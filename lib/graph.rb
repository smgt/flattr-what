require "neography"
require "./lib/user_node"
require "./lib/thing_node"

class Graph

  attr_reader :neo

  def initialize
    @neo = Neography::Rest.new(ENV['NEO4J_URL'] || "http://localhost:7474")
    @flattr = Flattr.new
    @index = 'flattr'
  end

  def create_or_update_thing(id, thing=nil)
    # Check if the thing already exist
    t = get_thing(id)
    if t && t.age < 3600
      return t
    end

    # If no thing was supplied fetch it from flattr
    if thing.nil?
      thing = @flattr.thing(id)
      # If there is no such thing on Flattr return nil
      return nil unless thing
    end

    # Check if there already exists a thing
    if t.nil?

      # Create the thing
      thing_node = neo.create_node("title" => thing.title, "thing_id" => thing.id, "created_at" => Time.now.to_i, "updated_at" => Time.now.to_i)

      # Add a index so we can search for it
      neo.add_node_to_index(@index, "thing_id", thing.id, thing_node)

      puts "Created thing id '#{thing.id}', node id '#{thing_node["self"]}'"
    else

      # Use the already existing thing
      thing_node = t.node

      # Update the properties
      neo.set_node_properties(thing_node, {"title" => thing.title, "updated_at" => Time.now.to_i})

      puts "Updated thing id '#{thing.id}', node id '#{thing_node["self"]}'"
    end

    # Wrapp the now node in a ThingNode object
    return ThingNode.new thing_node
  end

  def create_or_update_user(username)

    u = get_user(username)
    if u && u.age < 3600
      return u
    end

    # Check if the user exists at Flattr
    f_user = @flattr.user(username)
    return nil if f_user.nil?

    if u.nil?
      user_node = neo.create_node("username"   => username,
                                  "created_at" => Time.now.to_i,
                                  "updated_at" => Time.now.to_i,
                                  "scraped_at" => 0)
      neo.add_node_to_index(@index, "username", username, user_node)
    else
      user_node = u.node
      neo.set_node_properties(user_node, {"updated_at" => Time.now.to_i})
    end

    return UserNode.new user_node
  end

  def set_node_properties(node, params={})
    neo.set_node_properties(node, params)
  end

  def create_relationship(name, node1, node2)
    if neo.create_unique_relationship(@index, "rel_#{name}", "#{node1["self"].split("/").last}:#{node2["self"].split("/").last}", name, node1, node2)
      puts "Created relationship #{name} between #{node1["self"]} and #{node2["self"]}"
    else
      puts "NOT c relationship #{name} between #{node1["self"]} and #{node2["self"]}"
    end
  end

  def get_node(id)
    neo.get_node(id)
  end

  def get_thing(id)
    node = neo.get_node_index(@index, "thing_id", id)
    return nil if node.nil?
    return ThingNode.new node.first
  end

  def get_user(username)
    node = neo.get_node_index(@index, "username", username)
    return nil if node.nil?
    user = UserNode.new node.first
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

  def cypher(query)
    neo.execute_query(query)
  end

end
