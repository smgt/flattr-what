require "rubygems"
require "sinatra/base"
require "neography"
require "flattr"

require './lib/graph'
require './lib/user_node'
require './lib/thing_node'

class App < Sinatra::Base

  layout :default

  get "/" do
    n = Graph.new
    erb :index
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

  post "/fetch/user" do
    g = Graph.new
    user_node = g.get_user params[:username]
    if !user_node || params[:force_refresh]
      result = g.create_user params[:username]
      if result
        puts "Creating new user #{params[:username]}"
        redirect to "/user/#{params[:username]}"
      else
        return "ERROR"
      end
    else
      puts "User '#{params[:username]}' already exists, redirecting"
      redirect to "/user/#{params[:username]}"
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
