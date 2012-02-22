class ThingNode
  attr_reader :id, :node_id

  def initialize(node)
    data = node.first["data"]
    @id = data["thing_id"]
    @node_id = node.first['self'].split("/").last
    @thing_data = false
  end

  def data
    flattr = Flattr.new
    @thing_data ||= flattr.thing(@id)
  end

  def relations(direction=:all)
    g = Graph.new
    g.fetch_relationships @node, direction.to_s
  end

end
