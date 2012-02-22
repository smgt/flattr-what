class Graph

  attr_reader :neo

  def initialize
    @neo = Neography::Rest.new(ENV['NEO4J_URL'] || "http://localhost:7474")
    @flattr = Flattr.new
    @index = 'flattr'
  end

  def create_thing(id)
    thing = @flattr.thing id
    return nil if thing.nil?
    node = neo.create_node("title" => thing.title, "thing_id" => thing.id)
    return nil if node.nil?
    neo.add_node_to_index(@index, "thing_id", thing.id, node)
    return node
  end

  def create_user(username)
    user = @flattr.user username
    return nil if user.nil?
    node = neo.create_node("username" => username)
    return nil if node.nil?
    neo.add_node_to_index(@index, "username", username, node)
    return node
  end

  def create_relationship(node1, node2, name)
    
  end

  def get_node(id)
    neo.get_node(id)
  end

  def get_thing(id)
    node = neo.get_node_index(@index, "thing_id", id)
    return nil if node.nil?
    thing = ThingNode.new node
    thing
  end

  def get_user(username)
    node = neo.get_node_index(@index, "username", username)
    return nil if node.nil?
    user = UserNode.new node
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
