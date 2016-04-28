require "../spec_helper"

describe Tjeneste::Routing::RouterPrinter do

  it "prints multiple nodes as a tree" do
    root = InnerNode.new(children: [
      TerminalNode.new(
        matchers: [
          VerbMatcher.new(Tjeneste::Routing::Verb::POST),
          PathMatcher.new("users/")
        ]
      ),
      InnerNode.new(
        matchers: [
          PathMatcher.new("topics/")
        ],
        children: [
          TerminalNode.new(
            matchers: [
              VerbMatcher.new(Tjeneste::Routing::Verb::GET),
              PathMatcher.new(:int)
            ]
          )
        ]
      )
    ])
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
