require "rubygems"
require "sinatra/base"
require "neography"
require "flattr"

class UserNode
  attr_reader :username, :node_id

  def initialize(node)
    puts node.inspect
    data = node.first["data"]
    @username = data["username"]
    @node_id = node.first["self"].split("/").last
    @node = node.first
    @user_data = false
  end

  def data
    flattr = Flattr.new
    @user_data ||= flattr.user(@username)
  end

  def relations(direction=:all)
    g = Graph.new
    g.fetch_relationships @node, direction.to_s
  end

end

class ThingNode
  attr_reader :id, :node_id

  def initialize(node)
    data = node.first["data"]
    @id = data["thing_id"]
    @node_id = node.first['self'].split("/").last
    @thing_data = false
  end

  def data
    flattr = Flattr.new
    @thing_data ||= flattr.thing(@id)
  end

  def relations(direction=:all)
    g = Graph.new
    g.fetch_relationships @node, dorecition.to_s
  end

end

class Graph

  attr_reader :neo

  def initialize
    @neo = Neography::Rest.new(ENV['NEO4J_URL'] || "http://localhost:7474")
    @flattr = Flattr.new
    @index = 'flattr'
  end

  def create_thing(id)
    thing = @flattr.thing id
    return nil if thing.nil?
    node = neo.create_node("title" => thing.title, "thing_id" => thing.id)
    return nil if node.nil?
    neo.add_node_to_index(@index, "thing_id", thing.id, node)
    return node
  end

  def create_user(username)
    user = @flattr.user username
    return nil if user.nil?
    node = neo.create_node("username" => username)
    return nil if node.nil?
    neo.add_node_to_index(@index, "username", username, node)
    return node
  end

  def get_node(id)
    self.neo.get_node(id)
  end

  def get_thing(id)
    node = neo.get_node_index(@index, "thing_id", id)
    return nil if node.nil?
    thing = ThingNode.new node
    thing
  end

  def get_user(username)
    node = neo.get_node_index(@index, "username", username)
    return nil if node.nil?
    user = UserNode.new node
    user
  end

  def find_node_by(query)
    neo.find_node_index(@index, query )
  end

  def add_to_index(id, key)
    node = neo.get_node(id)
    value = node["data"][key]
    self.neo.add_node_to_index(@index, key, value, node)
  end

  def fetch_relationships(node,direction=:all)
    neo.get_node_relationships(node,direction.to_s)
  end

end

class App < Sinatra::Base

  layout :default

  get "/" do
    n = Graph.new
    erb :index
  end

  get "/add_to_index/:id" do
    g = Graph.new
    g.add_to_index params[:id], "name"
    return "OK i guess"
  end

  get "/node/:id" do
    g = Graph.new
    n = g.get_node params[:id]
    erb :node, :locals => {:node => n}
  end

  get "/user/:username" do
    g = Graph.new
    user = g.get_user params[:username]
    redirect to "/fetch/user/#{params[:username]}" if user.nil?
    erb :user, :locals => { :user => user }
  end

  get "/thing/:id" do
    g = Graph.new
    thing = g.get_thing params[:id]
    redirect to "/fetch/thing/#{params[:id]}" if thing.nil?
    erb :thing, :locals => { :thing => thing }
  end

  get "/fetch/thing/:id" do
    g = Graph.new
    result = g.create_thing params[:id]
    if result
      redirect to "/thing/#{params[:id]}"
    else
      return "ERROR"
    end
  end

  get "/fetch/user/:username" do
    g = Graph.new
    result = g.create_user params[:username]
    if result
      redirect to "/user/#{params[:username]}"
    else
      return "ERROR"
    end
  end

end
