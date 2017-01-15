module Tjeneste
  module Routing
    class Router
      class NoRouteFoundException < Exception
        def initialize(@request : HTTP::Request)
          super(to_s)
        end

        def to_s
          "No route found for: #{@request.method} #{@request.path}"
        end
      end

      getter logger : Logger

      def initialize(root_node : Node, @logger = Logger.new(STDOUT))
        # The root nodes matchers are not checked in #route, therefore
        # the passed root node has to be wrapped.
        # @internal_root = InnerNode.new(children: [root_node] of Node)
        @internal_root = root_node
      end

      def root
        # @internal_root.children.first
        @internal_root
      end

      def route(request : HTTP::Request) : Route?
        node_path = [] of Node
        state = RoutingState.new(request)
        # reqs = [req] of RoutingState

        queue = [@internal_root]

        while node = queue.shift?
          # puts [
          #   node.depth,
          #   node.class.name.sub(/Tjeneste::Routing::/, ""),
          #   state.inspect,
          #   state.remaining_segments?,
          #   node.matchers.map { |m| m.to_s },
          # ].join(" - ")
          case node
          when TerminalNode
            if next_state = node.match(state)
              if !next_state.remaining_segments?
                node_path << node
                return Route.new(node_path, node.action)
              end
            end
          when InnerNode
            if next_state = node.match(state)
              state = next_state
              node_path << node
              queue += node.children
            end
          else raise "unknown node type"
          end
        end
      end

      def route!(request : HTTP::Request) : Route
        if r = route(request)
          r
        else
          raise NoRouteFoundException.new(request)
        end
      end

      def traverse_depth_first(&callback : Node -> Nil)
        fifo = [root]

        while node = fifo.shift?
          case node
          when InnerNode
            callback.call(node)
            fifo = node.children + fifo
          when TerminalNode
            callback.call(node)
          else raise "not handled"
          end
        end
      end

      def inspect(io : IO)
        io << "Router(root: #{root})"
      end
    end
  end
end
