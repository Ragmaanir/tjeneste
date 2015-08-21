require "../spec_helper"

describe Tjeneste::Routing::RouterPrinter do

  it "" do
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

    # FIXME crystal bug? why no \n at the end of second line?
    tree = <<-TREE
InnerNode: \n
  TerminalNode: POST users/
  InnerNode: topics/\n
    TerminalNode: GET int
TREE

    assert RouterPrinter.print(router) == tree
  end

end
