require "./../spec_helper"

describe Tjeneste::Routing::RouterBuilder do
  InnerNode      = Tjeneste::Routing::InnerNode
  TerminalNode   = Tjeneste::Routing::TerminalNode
  VerbConstraint = Tjeneste::Routing::VerbRoutingConstraint
  PathConstraint = Tjeneste::Routing::PathRoutingConstraint

  GetConstraint  = VerbConstraint.new(Tjeneste::Routing::Verb::GET)
  PostConstraint = VerbConstraint.new(Tjeneste::Routing::Verb::POST)

  NO_CONSTRAINTS = [] of Tjeneste::Routing::RoutingConstraint

  class MyHandler
    include HTTP::Handler

    def initialize
    end

    def call(ctx : HTTP::Server::Context)
      ctx.response.status_code = 302
      nil
    end
  end

  test "generates nested routes with appropriate constraints" do
    handler = MyHandler.new

    router = Tjeneste::Routing::RouterBuilder.build do
      path("users") do
        get "", handler
      end
    end

    assert router
    assert router.is_a?(Tjeneste::Routing::Router)

    routing_tree = InnerNode.new(
      constraints: NO_CONSTRAINTS,
      children: [
        InnerNode.new(
          constraints: [PathConstraint.new("users")],
          children: [
            TerminalNode.new(
              constraints: [
                GetConstraint,
              ],
              action: handler
            ),
          ]
        ),
      ]
    )

    assert router.root == routing_tree
  end

  test "complicated nested routes" do
    router = Tjeneste::Routing::RouterBuilder.build do
      get "", Tjeneste::EmptyBlock
      path "topics" do
        get :int, Tjeneste::EmptyBlock

        path "comments" do
          get "", Tjeneste::EmptyBlock
          post "", Tjeneste::EmptyBlock
          get :int, Tjeneste::EmptyBlock
        end
      end
    end

    routing_tree = InnerNode.new(
      constraints: NO_CONSTRAINTS,
      children: [
        TerminalNode.new(
          constraints: [
            GetConstraint,
          ],
          action: Tjeneste::EmptyBlock
        ),
        InnerNode.new(
          constraints: [PathConstraint.new("topics")],
          children: [
            TerminalNode.new(
              constraints: [
                GetConstraint,
                PathConstraint.new(:int),
              ],
              action: Tjeneste::EmptyBlock
            ),
            InnerNode.new(
              constraints: [PathConstraint.new("comments")],
              children: [
                TerminalNode.new(
                  constraints: [GetConstraint],
                  action: Tjeneste::EmptyBlock
                ),
                TerminalNode.new(
                  constraints: [PostConstraint],
                  action: Tjeneste::EmptyBlock
                ),
                TerminalNode.new(
                  constraints: [
                    GetConstraint,
                    PathConstraint.new(:int),
                  ],
                  action: Tjeneste::EmptyBlock
                ),
              ]
            ),
          ]
        ),
      ]
    )

    assert router.root == routing_tree
  end

  test "mounting" do
    handler = MyHandler.new
    router = Tjeneste::Routing::RouterBuilder.build do
      mount "", handler
    end

    routing_tree = InnerNode.new(
      constraints: NO_CONSTRAINTS,
      children: [
        TerminalNode.new(
          constraints: [
            PathConstraint.new(""),
          ],
          action: handler
        ),
      ]
    )

    assert router.root == routing_tree
  end
end
