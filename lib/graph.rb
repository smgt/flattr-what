class Graph

  attr_reader :neo

  def initialize
    @neo = Neography::Rest.new(ENV['NEO4J_URL'] || "http://localhost:7474")
    @flattr = Flattr.new
    @index = 'flattr'
  end

  def create_thing(id, thing=nil)
    # Check if the thing already exist
    if t = get_thing(id)
      return t
    end

    # If no thing was supplied fetch it from flattr
    if thing.nil?
      thing = @flattr.thing(id)
      return nil unless thing
    end

    # Create the thing
    thing_node = neo.create_node("title" => thing.title, "thing_id" => thing.id)
    neo.add_node_to_index(@index, "thing_id", thing.id, thing_node)
    puts "Created thing id '#{thing.id}', node id '#{thing_node["self"]}'"
    return ThingNode.new thing_node
  end

  def create_user(username, fetch_from_flattr = true)
    user = get_user(username)
    unless user
      # why is this even here? only to verify?
      user_raw = @flattr.user username if fetch_from_flattr
      puts user_raw.inspect
      if user_raw || !fetch_from_flattr
        user_node = neo.create_node("username" => username)
        neo.add_node_to_index(@index, "username", username, user_node)
        user = UserNode.new user_node
      end
    end
    return user
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
