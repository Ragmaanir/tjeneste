require "./../spec_helper"

describe Tjeneste::Routing::RouterBuilder do
  InnerNode    = Tjeneste::Routing::InnerNode
  TerminalNode = Tjeneste::Routing::TerminalNode

  class MyHandler < HTTP::Handler
    def initialize
    end

    def call(ctx : HTTP::Server::Context)
      ctx.response.status_code = 302
      nil
    end
  end

  test "generates nested routes with appropriate matchers" do
    # action = ->(ctx : HTTP::Server::Context) do
    #   ctx.response.status_code = 302
    #   nil
    # end
    handler = MyHandler.new

    router = Tjeneste::Routing::RouterBuilder.build do |r|
      r.path("users") do |r|
        r.get "", handler
      end
    end

    assert router
    assert router.is_a?(Tjeneste::Routing::Router)

    routing_tree = InnerNode.new(
      matchers: [PathMatcher.new("/")],
      children: [
        InnerNode.new(
          matchers: [Tjeneste::Routing::PathMatcher.new("users/")],
          children: [
            TerminalNode.new(
              matchers: [
                Tjeneste::Routing::PathMatcher.new(""),
                Tjeneste::Routing::VerbMatcher.new(Tjeneste::Routing::Verb::GET),
              ],
              action: handler
            ),
          ]
        ),
      ]
    )

    assert router.root == routing_tree
  end

  test "mounting" do
    router = Tjeneste::Routing::RouterBuilder.build do |r|
      r.mount "", MyHandler
    end

    routing_tree = InnerNode.new(
      matchers: [PathMatcher.new("/")],
      children: [
        TerminalNode.new(
          matchers: [
            Tjeneste::Routing::PathMatcher.new(""),
            Tjeneste::Routing::VerbMatcher.new(Tjeneste::Routing::Verb::GET),
          ],
          action: BlockHandler.new { |ctx| MyHandler.new.call(ctx); nil }
        ),
      ]
    )

    # FIXME == comparison does not work for closures
    # assert router.root == routing_tree
  end
end
