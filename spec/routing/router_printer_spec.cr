require "../spec_helper"

describe Tjeneste::Routing::RouterPrinter do
  TN = Tjeneste::Routing::TerminalNode

  test "prints multiple nodes as a tree" do
    root = InnerNode.new(children: [
      TN.new(
        matchers: [
          VerbMatcher.new(Tjeneste::Routing::Verb::POST),
          PathMatcher.new("users/"),
        ] of Matcher
      ),
      InnerNode.new(
        matchers: [
          PathMatcher.new("topics/"),
        ] of Matcher,
        children: [
          TN.new(
            matchers: [
              VerbMatcher.new(Tjeneste::Routing::Verb::GET),
              PathMatcher.new(:int),
            ] of Matcher
          ),
        ] of Tjeneste::Routing::Node
      ),
    ] of Tjeneste::Routing::Node)
    router = Tjeneste::Routing::Router.new(root)

    tree = <<-TREE
    InnerNode:
      TerminalNode: POST users/
      InnerNode: topics/
        TerminalNode: GET int
    TREE

    assert RouterPrinter.print(router) == tree
  end
end
