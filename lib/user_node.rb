class UserNode
  attr_reader :username, :node_id

  def initialize(node)
    data = node["data"]
    @username = data["username"]
    @node_id = node["self"].split("/").last
    @node = node
    @user_data = false
  end

  def data
    flattr = Flattr.new
    @user_data ||= flattr.user(@username)
  end

  def relations(direction=:all)
    g = Graph.new
    g.fetch_relationships @node, direction.to_s
  end

  def node
    @node
  end

end
