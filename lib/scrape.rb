class Scrape

  class << self

    def user(username)
      flattr = Flattr.new
      graph = Graph.new

      # Check if the flattr user exists
      f_user = flattr.user(username)
      return nil unless f_user

      puts "Scrape.user:: Flattr user #{username} exists"

      # Create the user in the graph
      g_user = graph.create_or_update_user username
      return nil unless g_user

      # Dont scrape if users flattrs have been recently scrapted 
      puts "will check g_user.scrape?:continue?(#{g_user.scrape?})"
      return nil unless g_user.scrape?

      # Update last time a user was scraped
      graph.set_node_properties(g_user.node, {"scraped_at" => Time.now.to_i})

      puts "set node property scrape_at #{g_user.node['data']['scraped_at']}"

      puts "Scrape.user:: Created graph node for #{username}"

      f_user_things = flattr.user_things(username, :count => 30)
      f_user_things.each do |thing|
        g_thing = graph.create_or_update_thing(thing.id, thing)
        if g_thing
          puts "Created node #{g_thing.data.id}..."
          graph.create_relationship("owner", g_thing.node, g_user.node)
        end
      end


      # Fetch the users flattrs
      f_user_flattrs = flattr.user_flattrs(username, :count => 30)
      return nil unless f_user_flattrs

      puts "Scrape.user:: Found #{f_user_flattrs.length} to scrape.."

      # Find all the things the user have flattred
      things = f_user_flattrs.collect do |flattr|
        # Add them to the graph
        g_thing = graph.create_or_update_thing(flattr['thing']['id'], Flattr::Thing.new(flattr['thing']) )
        puts "Created/fetched node for thing #{g_thing.data.id}..."
        if g_thing
          graph.create_relationship('flattr', g_user.node, g_thing.node)
          g_thing
        end
      end

      things.each do |thing_node|
        puts "Fetching flattrs for thing #{thing_node.data.id}..."
        f_thing_flattrs = flattr.get("/rest/v2/things/#{thing_node.data.id}/flattrs", :count => 30)
        if f_thing_flattrs #&& f_thing_flattrs['error'].nil?
          puts "Found #{f_thing_flattrs.size} flattrs..."
          f_thing_flattrs.each do |flattr|
            if !flattr['owner'].nil? && !flattr['owner']['username'].nil?
              g_user = graph.create_or_update_user(flattr['owner']['username'])
              if g_user
                graph.create_relationship('flattr', g_user.node, thing_node.node)
              end
            end
          end
        end
      end


      return true
    end

  end
end
