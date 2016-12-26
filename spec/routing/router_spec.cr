# require "../spec_helper"

# describe Tjeneste::Routing::Router do
#   TN = Tjeneste::Routing::TerminalNode

#   test "returns routes when routing is successful" do
#     root = InnerNode.new(children: [
#       TN.new(matchers: [PathMatcher.new("users")]),
#       TN.new(matchers: [PathMatcher.new("topics")]),
#     ])

#     router = Tjeneste::Routing::Router.new(root)

#     req = HTTP::Request.new("GET", "/users")

#     route = router.route!(req)

#     path = route.path
#     expected = [root, root.children.first]
#     assert path == expected
#     # FIXME this one causes errors with powe-assert
#     # assert route.path == [root, root.children.first]

#     req = HTTP::Request.new("GET", "/not_found")

#     route = router.route(req)

#     assert route == nil
#   end

#   test "matches nested paths" do
#     root = InnerNode.new(
#       matchers: [PathMatcher.new("users")],
#       children: [
#         InnerNode.new(
#           matchers: [PathMatcher.new("special")],
#           children: [
#             TN.new(matchers: [PathMatcher.new(:int)]),
#           ]
#         ),
#       ]
#     )

#     router = Tjeneste::Routing::Router.new(root)

#     req = HTTP::Request.new("GET", "/users/special/1")

#     route = router.route(req)

#     assert route
#   end

#   test "matches HTTP verbs" do
#     root = TN.new(
#       matchers: [
#         PathMatcher.new("users"),
#         VerbMatcher.new(Tjeneste::Routing::Verb::POST),
#       ]
#     )

#     router = Tjeneste::Routing::Router.new(root)

#     req = HTTP::Request.new("POST", "/users/special/1")

#     route = router.route(req)

#     assert route

#     #
#     req = HTTP::Request.new("GET", "/users/special/1")

#     route = router.route(req)

#     assert !route
#   end
# end
