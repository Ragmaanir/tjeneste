require "./../spec_helper"

describe Tjeneste::Routing::RouterBuilder do
  InnerNode    = Tjeneste::Routing::InnerNode
  TerminalNode = Tjeneste::Routing::TerminalNode
  VerbMatcher  = Tjeneste::Routing::VerbMatcher
  PathMatcher  = Tjeneste::Routing::PathMatcher

  GetMatcher  = VerbMatcher.new(Tjeneste::Routing::Verb::GET)
  PostMatcher = VerbMatcher.new(Tjeneste::Routing::Verb::POST)

  class MyHandler
    include HTTP::Handler

    def initialize
    end

    def call(ctx : HTTP::Server::Context)
      ctx.response.status_code = 302
      nil
    end
  end

  test "generates nested routes with appropriate matchers" do
    handler = MyHandler.new

    router = Tjeneste::Routing::RouterBuilder.build do
      path("users") do
        get "", handler
      end
    end

    assert router
    assert router.is_a?(Tjeneste::Routing::Router)

    routing_tree = InnerNode.new(
      matchers: [] of Tjeneste::Routing::Matcher,
      children: [
        InnerNode.new(
          matchers: [PathMatcher.new("users")],
          children: [
            TerminalNode.new(
              matchers: [
                GetMatcher,
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
      matchers: [] of Tjeneste::Routing::Matcher,
      children: [
        TerminalNode.new(
          matchers: [
            GetMatcher,
          ],
          action: Tjeneste::EmptyBlock
        ),
        InnerNode.new(
          matchers: [PathMatcher.new("topics")],
          children: [
            TerminalNode.new(
              matchers: [
                GetMatcher,
                PathMatcher.new(:int),
              ],
              action: Tjeneste::EmptyBlock
            ),
            InnerNode.new(
              matchers: [PathMatcher.new("comments")],
              children: [
                TerminalNode.new(
                  matchers: [GetMatcher],
                  action: Tjeneste::EmptyBlock
                ),
                TerminalNode.new(
                  matchers: [PostMatcher],
                  action: Tjeneste::EmptyBlock
                ),
                TerminalNode.new(
                  matchers: [
                    GetMatcher,
                    PathMatcher.new(:int),
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
      matchers: [] of Matcher,
      children: [
        TerminalNode.new(
          matchers: [
            PathMatcher.new(""),
          ],
          action: handler
        ),
      ]
    )

    assert router.root == routing_tree
  end
end
