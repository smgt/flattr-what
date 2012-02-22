class Populator


  class << self

    def scrape_things_owned_by username
      raw_things = f.user_things(username, {:count => 50})

      user_thing_relations = 0
      raw_things.each do |thing|
        thing = g.create_thing(thing.id)
        g.create_relationship("owner", thing.node, user.node)
        g.create_relationship("owner", user.node, thing.node)
      end

      raw_things
    end

    def scrape_things_flattred_by username
      flattr_relations = 0
      raw_flattrings = f.user_flattrs(username, {:full => "full", :count => 50})

      raw_flattrings.each do |click|
        thing = g.create_thing(click["thing"]["id"], Flattr::Thing.new(click["thing"]))
        if thing
          flattr_relations = flattr_relations + 1
          g.create_relationship("flattred", user.node, thing.node)
          g.create_relationship("flattred_by", thing.node, user.node)
        end
      end
      return raw_flattrings.collect{|f| f["thing"]}

    end


    def scrape(username)
      user = g.create_user username
      return nil unless user

      owned_things    = self.scrape_things_by_user username
      flattred_things = self.scrape_things_flattred_by username

      self.scrape_users_by_flattred_things flattred_things


    end

    def scrape_users_by_flattred_things flattred_things
      flattred_things.each do |raw_thing|
        raw_flattrings = f.get("things/#{raw_thing["id"]}/flattrs")
        if raw_flattrings
          raw_flattrings.each do |raw_flattr|
            user = g.create_user raw_flattr["owner"]["username"], false
            self.scrape_things_by_username raw_flattr["owner"]["username"]

            # needs thing node!
            #g.create_relationship("flattred_by", thing, user)
            #g.create_relationship("flattred", user, thing)
          end
      end
    end

    def g
      @@graph || Graph.new
    end

    def f
      @@flattr || Flattr.new
    end

  end

end
