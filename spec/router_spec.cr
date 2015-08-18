require "./spec_helper"

describe Tjeneste::Router do
  Node = Tjeneste::Router::Node
  it "" do
    root = Node.new(children: [
      Node.new(segment: "users"),
      Node.new(segment: "topics")
    ])
    router = Tjeneste::Router.new(root)

    req = HTTP::Request.new("GET", "users")

    route = router.route(req)
    
    case route
    when nil then fail("route was nil")
    when Tjeneste::Router::Route then assert route.path == [root, root.children.first]
    end
  end
end
