class Graph

  attr_reader :neo

  def initialize
    @neo = Neography::Rest.new(ENV['NEO4J_URL'] || "http://localhost:7474")
    @flattr = Flattr.new
    @index = 'flattr'
  end

  def create_thing(id, thing_raw = {})
    thing = get_thing(id)
    unless thing
      unless thing_raw = @flattr.thing(id)
        puts "unable to find thing #{id} in flattr"
        return nil
      end
      thing_node = neo.create_node("title" => thing_raw.title, "thing_id" => thing_raw.id)
      neo.add_node_to_index(@index, "thing_id", thing_raw.id, thing_node)
      thing = ThingNode.new thing_node
      puts "Created thing id '#{thing_raw.id}', node id '#{thing_node["self"]}'"
    else
      puts "node was already in db: #{thing.node['self']}"
    end
    return thing
  end

  def create_user(username, fetch_from_flattr = true)
    user = get_user(username)
    unless user
      # why is this even here? only to verify?
      user_raw = @flattr.user username if fetch_from_flattr
      if user_raw || !fetch_from_flattr
        user_node = neo.create_node("username" => username)
        neo.add_node_to_index(@index, "username", username, user_node)
        user = UserNode.new user_node
      end
    end
    return user
  end

  def create_relationship(name, node1, node2)
    #neo.create_relationship(name, node1, node2)
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
    thing = ThingNode.new node.first
    thing
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

end
