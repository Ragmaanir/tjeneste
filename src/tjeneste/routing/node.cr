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
        node = parent
        i = 0
        while node
          i += 1
          node = node.parent
        end

        i
      end

      def match(request : RoutingState) : RoutingState?
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

      # abstract def to_s : String

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

      def to_s(io : IO)
        m = matchers.map(&.to_s).join(", ")
        c = children.map { |c| "#{c}" }.join(",")
        io << "Node(matchers: [#{m}], children: [#{c}])"
      end

      def inspect(io : IO)
        to_s(io)
      end
    end

    class TerminalNode < Node
      class EmptyHandler < HTTP::Handler
        def call(ctx : HTTP::Server::Context)
          ctx.response.puts "EmptyHandler"
          ctx.response.status_code = 200
        end
      end

      getter action : Action | HTTP::Handler | HttpBlock

      def initialize(matchers : Array(Matcher), @action : Action)
        super(matchers)
      end

      def initialize(
                     matchers = [] of Matcher,
                     @action : HTTP::Handler | HttpBlock = EmptyHandler.new)
        super(matchers)
      end

      def ==(other : TerminalNode)
        super && action == other.action
      end

      def ==(other : Node)
        false
      end

      def to_s(io : IO)
        m = matchers.map(&.to_s).join(", ")
        io << "TerminalNode(matchers: [#{m}], action: #{action})"
      end

      def inspect(io : IO)
        to_s(io)
      end
    end
  end
end
