require "rubygems"
require "sinatra/base"
require "neography"
require "flattr"

require './lib/graph'
require './lib/scrape'
require './lib/user_node'
require './lib/thing_node'



class App < Sinatra::Base

  if development?
    Flattr.configure do |config|
      config.endpoint = "https://api.flattr.dev/"
    end
  end

  not_found do
    erb :not_found
  end


  layout :default

  get "/" do
    erb :index
  end

  get "/node/:id" do
    g = Graph.new
    n = g.get_node params[:id]
    erb :node, :locals => {:node => n}
  end

  get "/about" do
    erb :about
  end

  get "/user/:username" do
    g = Graph.new
    user = g.get_user params[:username]
    halt 404, params[:username] if user.nil?
    r = g.cypher("START root_user = node(#{user.node_id}) MATCH root_user-[:flattr]->()<-[:flattr]-user-[:flattr]->things WHERE not(root_user-->things) RETURN things.thing_id, things.title, count(*) AS count ORDER BY count DESC LIMIT 10")
    things = r["data"]
    erb :user, :locals => { :user => user, :r => r, :things => things }
  end

  get "/thing/:id" do
    g = Graph.new
    thing = g.get_thing params[:id]
    redirect to "/fetch/thing/#{params[:id]}" if thing.nil?
    erb :thing, :locals => { :thing => thing }
  end

  get "/fetch/thing/:id" do
    g = Graph.new
    result = g.create_or_update_thing params[:id]
    if result
      redirect to "/thing/#{params[:id]}"
    else
      return "ERROR"
    end
  end

  post "/fetch/user" do
    g = Graph.new
    Scrape.user params[:username]
    puts "Scraped user #{params[:username]}"
    redirect to "/user/#{params[:username]}"
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
