require "../spec_helper"

describe Tjeneste::Routing::Router do

  it "returns routes when routing is successful" do
    root = InnerNode.new(matchers: [PathMatcher.new("/")], children: [
      TerminalNode.new(matchers: [PathMatcher.new("users")]),
      TerminalNode.new(matchers: [PathMatcher.new("topics")])
    ])
    router = Tjeneste::Routing::Router.new(root)

    req = HTTP::Request.new("GET", "/users")

    route = router.route!(req)

    assert route.path == [root, root.children.first]

    req = HTTP::Request.new("GET", "not_found")

    route = router.route(req)

    assert route == nil
  end

  it "matches nested paths" do
    root = InnerNode.new(
      matchers: [PathMatcher.new("/")],
      children: [
        InnerNode.new(matchers: [PathMatcher.new("users/")], children: [
          InnerNode.new(matchers: [PathMatcher.new("special/")], children: [
            TerminalNode.new(matchers: [PathMatcher.new(:int)])
          ])
        ])
      ]
    )
    router = Tjeneste::Routing::Router.new(root)

    req = HTTP::Request.new("GET", "/users/special/1")

    route = router.route(req)

    assert route
  end

  it "matches HTTP verbs" do
    root = InnerNode.new(
      matchers: [PathMatcher.new("/")],
      children: [
        TerminalNode.new(
          matchers: [
            PathMatcher.new("users/"),
            VerbMatcher.new(Tjeneste::Routing::Verb::POST)
          ]
        )
      ]
    )
    router = Tjeneste::Routing::Router.new(root)

    req = HTTP::Request.new("POST", "/users/special/1")

    route = router.route(req)

    assert route

    #
    req = HTTP::Request.new("GET", "/users/special/1")

    route = router.route(req)

    assert !route
  end

end
