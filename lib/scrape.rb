class Scrape

  class << self

    def user(username, depth = 1)
      flattr = Flattr.new
      graph = Graph.new

      # Check if the flattr user exists
      f_user = flattr.user(username)
      return nil unless f_user

      puts "Scrape.user:: Flattr user #{username} exists"

      # Create the user in the graph
      g_user = graph.create_user username
      return nil unless g_user

      puts "Scrape.user:: Created graph node for #{username}"

      # Fetch the users flattrs
      f_user_flattrs = flattr.user_flattrs(username, :count => 30)
      return nil unless f_user_flattrs

      puts "Scrape.user:: Found #{f_user_flattrs.length} to scrape.."

      # Find all the things the user have flattred
      things = f_user_flattrs.collect do |flattr|
        # Add them to the graph
        g_thing = graph.create_thing(flattr['thing']['id'], Flattr::Thing.new(flattr['thing']) )
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
              g_user = graph.create_user(flattr['owner']['username'])
              if g_user
                graph.create_relationship('flattr', g_user.node, thing_node.node)
              end
            end
          end
        end
      end

      # if depth > 0
      #   Scrape.user flattr['owner']['username'], (depth - 1)
      # end


      return true
    end

    def thing(id)
    end

  end
end
