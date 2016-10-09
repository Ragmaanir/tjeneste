module Tjeneste
  module Routing
    abstract class Node
      property parent : Node?
      getter matchers : Array(Matcher)

      def initialize(matchers = [] of Matcher)
        @matchers = [] of Matcher
        matchers.each { |m| @matchers << m }
      end

      def root?
        parent == nil
      end

      def depth : Int
        # if parent
        #   parent.depth + 1
        # else
        #   0
        # end
        node = parent
        i = 0
        while node
          i += 1
          node = node.parent
        end

        i
      end

      def match(request : RequestState) : RequestState?
        results = [] of MatchResult

        all_match = matchers.all? do |m|
          res = m.match(request)
          results << res
          case res
          when MatchSuccess then request = res.request
          end
        end

        request if all_match
      end

      abstract def to_s : String

      def ==(other : Node)
        matchers == other.matchers
      end
    end

    class InnerNode < Node
      getter children : Array(Node)

      def initialize(
                     matchers = [] of Matcher,
                     children = [] of Node)
        super(matchers)
        @children = [] of Node
        children.each { |c| @children << c }
        @children.each { |c| c.parent = self }
      end

      def ==(other : InnerNode)
        super && children == other.children
      end

      def ==(other : Node)
        false
      end

      def to_s
        "Node(matchers: #{matchers}, children: [#{children.map { |c| c.to_s.as(String) }.join(",")}])"
      end
    end

    class TerminalNode < Node
      class EmptyHandler < HTTP::Handler
        def call(ctx : HTTP::Server::Context)
          ctx.response.puts "EmptyHandler"
          ctx.response.status_code = 200
        end
      end

      getter action : Action | HTTP::Handler

      def initialize(matchers : Array(Matcher), @action : Action)
        super(matchers)
      end

      def initialize(
                     matchers = [] of Matcher,
                     @action : HTTP::Handler = EmptyHandler.new)
        super(matchers)
      end

      def ==(other : TerminalNode)
        super && action == other.action
      end

      def ==(other : Node)
        false
      end

      def to_s
        "TerminalNode(matchers: #{matchers}, action: #{action})"
      end
    end
  end
end
