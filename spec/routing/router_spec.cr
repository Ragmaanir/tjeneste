require "../spec_helper"

describe Tjeneste::Routing::Router do

  NODE = Tjeneste::Routing::Node
  PathMatcher = Tjeneste::Routing::PathMatcher
  VerbMatcher = Tjeneste::Routing::VerbMatcher

  it "" do
    root = NODE.new(matchers: [PathMatcher.new("/")], children: [
      NODE.new(matchers: [PathMatcher.new("users")]),
      NODE.new(matchers: [PathMatcher.new("topics")])
    ])
    router = Tjeneste::Routing::Router.new(root)

    req = HTTP::Request.new("GET", "/users")

    route = router.route(req)

    case route
    when nil then fail("route was nil")
    when Tjeneste::Routing::Route then assert route.path == [root, root.children.first]
    end

    req = HTTP::Request.new("GET", "not_found")

    route = router.route(req)

    assert route == nil
  end

  it "matches nested paths" do
    root = NODE.new(children: [
      NODE.new(matchers: [PathMatcher.new("users/")], children: [
        NODE.new(matchers: [PathMatcher.new("special/")], children: [
          NODE.new(matchers: [PathMatcher.new(:int)])
        ])
      ])
    ])
    router = Tjeneste::Routing::Router.new(root)

    req = HTTP::Request.new("GET", "users/special/1")

    route = router.route(req)

    assert route
  end

  it "matches HTTP verbs" do
    root = NODE.new(children: [
      NODE.new(matchers: [PathMatcher.new("users/"), VerbMatcher.new(Tjeneste::Routing::Verb::POST)])
    ])
    router = Tjeneste::Routing::Router.new(root)

    req = HTTP::Request.new("POST", "users/special/1")

    route = router.route(req)

    assert route

    #
    req = HTTP::Request.new("GET", "users/special/1")

    route = router.route(req)

    assert !route
  end

end
