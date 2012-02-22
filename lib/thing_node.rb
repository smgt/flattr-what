class ThingNode
  attr_reader :id, :node_id

  def initialize(node)
    data = node["data"]
    @id = data["thing_id"].to_i
    @node_id = node['self'].split("/").last
    @node = node
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

  def node
    @node
  end

end
