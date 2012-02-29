require "rubygems"
require "sinatra/base"
require "qu-redis"

require './lib/graph'
require './lib/scrape'
require './lib/user_node'
require './lib/thing_node'

class App < Sinatra::Base

  not_found do
    erb :not_found
  end


  layout :default

  get "/" do
    erb :index
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

  post "/fetch/user" do

    g = Graph.new
    f = Flattr.new
    user_node = g.get_user(params[:username])
    if user_node
      Qu.enqueue Scrape, params[:username]
      redirect to "/user/#{params[:username]}"
    else
      user = f.user(params[:username])
      if user.username.nil?
        halt 404
      else
        Qu.enqueue Scrape, params[:username]
        redirect to "/scraping/#{params[:username]}"
      end
    end
  end

  get "/scraping/:username" do
    erb :scraping, :locals => {:username => params[:username]}
  end

end
