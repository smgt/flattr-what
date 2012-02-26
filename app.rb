require "rubygems"
require "sinatra/base"
require "neography"
require "flattr"

require './lib/graph'
require './lib/scrape'
require './lib/user_node'
require './lib/thing_node'

Flattr.configure do |config|
  config.endpoint = "https://api.flattr.dev/"
end

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
    r = g.cypher("START root_user = node(#{user.node_id}) MATCH root_user-[:flattr]->()<-[:flattr]-user-[:flattr]->things WHERE not(root_user-->things) RETURN things.thing_id, things.title, count(*) AS count ORDER BY count DESC")
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
    result = g.create_thing params[:id]
    if result
      redirect to "/thing/#{params[:id]}"
    else
      return "ERROR"
    end
  end

  post "/fetch/user" do
    g = Graph.new
    user = g.get_user params[:username]
    if !user || params[:force_refresh]

      Scrape.user params[:username], 2

      puts "Scraped user #{params[:username]}"

      # user = g.create_user params[:username]

      # if user
      #   f = Flattr.new

      #   things = f.user_things(params[:username], {:count => 50})

      #   user_thing_relations = 0
      #   things.each do |thing|
      #     user_thing_relations = user_thing_relations + 1
      #     thing = g.create_thing(thing.id)
      #     g.create_relationship("owner", thing.node, user.node)
      #     g.create_relationship("owner", user.node, thing.node)
      #   end

      #   flattr_relations = 0
      #   flattrings = f.user_flattrs(params[:username], {:full => "full", :count => 50})
      #   flattrings.each do |click|
      #     unless click["thing"]
      #       puts "click har ju for fan ingen hing: #{click.inspect}"
      #     end
      #     thing = g.create_thing(click["thing"]["id"], Flattr::Thing.new(click["thing"]))
      #     if thing
      #       flattr_relations = flattr_relations + 1
      #       g.create_relationship("flattred", user.node, thing.node)
      #       g.create_relationship("flattred_by", thing.node, user.node)
      #     end
      #   end

      #   puts "Created new user #{params[:username]} with #{user_thing_relations} "+
      #        "relations and #{flattr_relations} flattrings"
        # redirect to "/user/#{params[:username]}"
      # else
        # return "ERROR"
      # end

    else
      puts "User '#{params[:username]}' already exists, redirecting"
    end
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
