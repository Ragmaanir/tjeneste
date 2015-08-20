require "./spec_helper"

describe Tjeneste::RouterBuilder do

  Node = Tjeneste::Router::Node

  it "" do
    action = ->{ puts "show"; nil }

    router = Tjeneste::RouterBuilder.build do |r|
      r.path("users") do |r|
        r.get "", action
      end
    end

    assert router
    assert router.is_a?(Tjeneste::Router)

    routing_tree = Node.new(
      matchers: [Tjeneste::Router::PathMatcher.new("/")],
      children: [
        Node.new(
          matchers: [Tjeneste::Router::PathMatcher.new("users/")],
          children: [
            Node.new(
              matchers: [Tjeneste::Router::PathMatcher.new("")],
              action: action
            )
          ]
        )
      ]
    )

    assert router.root == routing_tree
  end
end
