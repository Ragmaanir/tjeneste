require "./spec_helper"

describe Tjeneste::Router do

  NODE = Tjeneste::Router::Node
  PathMatcher = Tjeneste::Router::PathMatcher
  VerbMatcher = Tjeneste::Router::VerbMatcher

  it "" do
    root = NODE.new(matchers: [PathMatcher.new("/")], children: [
      NODE.new(matchers: [PathMatcher.new("users")]),
      NODE.new(matchers: [PathMatcher.new("topics")])
    ])
    router = Tjeneste::Router.new(root)

    req = HTTP::Request.new("GET", "users")

    route = router.route(req)
    
    case route
    when nil then fail("route was nil")
    when Tjeneste::Router::Route then assert route.path == [root, root.children.first]
    end

    req = HTTP::Request.new("GET", "not_found")

    route = router.route(req)

    assert route == nil
  end

  it "matches nested paths" do
    root = NODE.new(matchers: [PathMatcher.new("/")], children: [
      NODE.new(matchers: [PathMatcher.new("users/")], children: [
        NODE.new(matchers: [PathMatcher.new("special/")], children: [
          NODE.new(matchers: [PathMatcher.new(:int)])
        ])
      ])
    ])
    router = Tjeneste::Router.new(root)

    req = HTTP::Request.new("GET", "users/special/1")

    route = router.route(req)

    assert route
  end

  it "matches HTTP verbs" do
    root = NODE.new(matchers: [PathMatcher.new("/")], children: [
      NODE.new(matchers: [PathMatcher.new("users/"), VerbMatcher.new(Tjeneste::Router::Verb::POST)])
    ])
    router = Tjeneste::Router.new(root)

    req = HTTP::Request.new("POST", "users/special/1")

    route = router.route(req)

    assert route

    #
    req = HTTP::Request.new("GET", "users/special/1")

    route = router.route(req)

    assert !route
  end

end
