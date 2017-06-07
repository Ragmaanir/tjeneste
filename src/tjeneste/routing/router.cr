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
        @internal_root = root_node
      end

      def root
        @internal_root
      end

      def route(request : HTTP::Request) : Route?
        state = RoutingState.new(request)

        children = [@internal_root]

        while node = children.shift?
          if next_state = node.match(state)
            case node
            when TerminalNode
              if node.ignore_remainder? || !next_state.remaining_segments?
                return Route.new(node.path, node.action, next_state.virtual_params)
              end
            when InnerNode
              state = next_state
              children = node.children.dup
            else raise "unknown node type"
            end
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
