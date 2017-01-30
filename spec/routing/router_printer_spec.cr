require "../spec_helper"

describe Tjeneste::Routing::RouterPrinter do
  TN = Tjeneste::Routing::TerminalNode

  test "prints multiple nodes as a tree" do
    root = InnerNode.new(children: [
      TN.new(
        constraints: [
          VerbRoutingConstraint.new(Tjeneste::Routing::Verb::POST),
          PathRoutingConstraint.new("users/"),
        ] of RoutingConstraint
      ),
      InnerNode.new(
        constraints: [
          PathRoutingConstraint.new("topics/"),
        ] of RoutingConstraint,
        children: [
          TN.new(
            constraints: [
              VerbRoutingConstraint.new(Tjeneste::Routing::Verb::GET),
              BindingPathConstraint.new("id", /\d+/),
            ] of RoutingConstraint
          ),
        ] of Tjeneste::Routing::Node
      ),
    ] of Tjeneste::Routing::Node)
    router = Tjeneste::Routing::Router.new(root)

    tree = <<-TREE
    InnerNode:
      TerminalNode: POST "users/"
      InnerNode: "topics/"
        TerminalNode: GET {"id" => /\\d+/}
    TREE

    assert RouterPrinter.print(router) == tree
  end
end
