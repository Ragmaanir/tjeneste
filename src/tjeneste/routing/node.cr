require "http"

module Tjeneste
  module Routing
    abstract class Node
      property parent : InnerNode?
      getter constraints : Array(RoutingConstraint)

      def initialize(constraints = [] of RoutingConstraint)
        @constraints = [] of RoutingConstraint
        constraints.each { |m| @constraints << m }
      end

      def root?
        parent == nil
      end

      def path : Array(Node)
        nodes = [] of Node
        node = parent
        while node
          nodes.unshift(node)
          node = node.parent
        end

        nodes
      end

      def depth : Int
        path.size
      end

      def match(request : RoutingState) : RoutingState?
        results = [] of MatchResult

        all_match = constraints.all? do |m|
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
        constraints == other.constraints
      end

      def compact_s
        "#{self.class.name.split("::").last}(#{constraints.map(&.to_s)})"
      end
    end

    class InnerNode < Node
      getter children : Array(Node)

      def initialize(
                     constraints = [] of RoutingConstraint,
                     children = [] of Node)
        super(constraints)
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
        m = constraints.map(&.to_s).join(", ")
        c = children.map { |c| "#{c}" }.join(",")
        io << "Node(constraints: [#{m}], children: [#{c}])"
      end

      def inspect(io : IO)
        to_s(io)
      end
    end

    class TerminalNode < Node
      class EmptyHandler
        include HTTP::Handler

        def call(ctx : HTTP::Server::Context)
          ctx.response.puts "EmptyHandler"
          ctx.response.status_code = 200
        end
      end

      EMPTY_HANDLER = EmptyHandler.new

      alias Actions = Action::AbstractLazyAction | Action::AbstractAction | HTTP::Handler | HttpBlock # FIXME action can be a class or an instance

      getter action : Actions

      def initialize(constraints : Array(RoutingConstraint), @action : Actions, @ignore_remainder : Bool = false)
        super(constraints)
      end

      def initialize(
                     constraints = [] of RoutingConstraint,
                     @action : HTTP::Handler | HttpBlock = EMPTY_HANDLER,
                     @ignore_remainder : Bool = false)
        super(constraints)
      end

      def ignore_remainder?
        @ignore_remainder
      end

      def ==(other : TerminalNode)
        super && action == other.action
      end

      def ==(other : Node)
        false
      end

      def to_s(io : IO)
        m = constraints.map(&.to_s).join(", ")
        io << "TerminalNode(constraints: [#{m}], action: #{action})"
      end

      def inspect(io : IO)
        to_s(io)
      end
    end
  end
end
