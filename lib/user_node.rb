class UserNode
  attr_reader :username, :node_id

  def initialize(node)
    @data = node["data"]
    @username = @data["username"]
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

  def age
    Time.now.to_i - @data['updated_at'].to_i
  end

  def updated_at
    @data['updated_at'] ||= 0
  end

  def created_at
    @data['created_at'] ||= 0
  end

  # determine if the flattrs and things of this owner
  # should be re-scraped or not
  def scrape?
    @data['scraped_at'].to_i < (Time.now.to_i - 3600)
  end

end
