require "./../spec_helper"

# describe Tjeneste::Routing::RouterBuilder do
#   InnerNode    = Tjeneste::Routing::InnerNode
#   TerminalNode = Tjeneste::Routing::TerminalNode
#   VerbMatcher  = Tjeneste::Routing::VerbMatcher
#   PathMatcher  = Tjeneste::Routing::PathMatcher

#   class MyHandler < HTTP::Handler
#     def initialize
#     end

#     def call(ctx : HTTP::Server::Context)
#       ctx.response.status_code = 302
#       nil
#     end
#   end

#   test "generates nested routes with appropriate matchers" do
#     handler = MyHandler.new

#     router = Tjeneste::Routing::RouterBuilder.build do
#       path("users") do
#         get "", handler
#       end
#     end

#     assert router
#     assert router.is_a?(Tjeneste::Routing::Router)

#     routing_tree = InnerNode.new(
#       matchers: [] of Tjeneste::Routing::Matcher,
#       children: [
#         InnerNode.new(
#           matchers: [PathMatcher.new("users")],
#           children: [
#             TerminalNode.new(
#               matchers: [
#                 VerbMatcher.new(Tjeneste::Routing::Verb::GET),
#                 PathMatcher.new(""),
#               ],
#               action: handler
#             ),
#           ]
#         ),
#       ]
#     )

#     assert router.root == routing_tree
#   end

#   test "mounting" do
#     handler = MyHandler.new
#     router = Tjeneste::Routing::RouterBuilder.build do
#       mount "", handler
#     end

#     routing_tree = InnerNode.new(
#       matchers: [] of Matcher,
#       children: [
#         TerminalNode.new(
#           matchers: [
#             PathMatcher.new(""),
#           ],
#           # action: BlockHandler.new { |ctx| MyHandler.new.call(ctx); nil }
#           action: handler
#         ),
#       ]
#     )

#     assert router.root == routing_tree
#   end
# end
