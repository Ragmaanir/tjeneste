require "./../spec_helper"

describe Tjeneste::Routing::RouterBuilder do

  Node = Tjeneste::Routing::Node

  it "" do
    action = ->(ctx : Tjeneste::Routing::HttpContext){ puts "show"; nil }

    router = Tjeneste::Routing::RouterBuilder.build do |r|
      r.path("users") do |r|
        r.get "", action
      end
    end

    assert router
    assert router.is_a?(Tjeneste::Routing::Router)

    routing_tree = Node.new(
      children: [
        Node.new(
          matchers: [Tjeneste::Routing::PathMatcher.new("users/")],
          children: [
            Node.new(
              matchers: [
                Tjeneste::Routing::PathMatcher.new(""),
                Tjeneste::Routing::VerbMatcher.new(Tjeneste::Routing::Verb::GET)
              ],
              action: action
            )
          ]
        )
      ]
    )

    assert router.root == routing_tree
  end
end
