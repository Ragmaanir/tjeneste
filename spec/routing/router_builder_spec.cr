require "./../spec_helper"

describe Tjeneste::Routing::RouterBuilder do

  InnerNode = Tjeneste::Routing::InnerNode
  TerminalNode = Tjeneste::Routing::TerminalNode

  it "generates nested routes with appropriate matchers" do
    action = ->(ctx : Tjeneste::Routing::HttpContext){ puts "show"; nil }

    router = Tjeneste::Routing::RouterBuilder.build do |r|
      r.path("users") do |r|
        r.get "", action
      end
    end

    assert router
    assert router.is_a?(Tjeneste::Routing::Router)

    routing_tree = InnerNode.new(
      children: [
        InnerNode.new(
          matchers: [Tjeneste::Routing::PathMatcher.new("users/")],
          children: [
            TerminalNode.new(
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
