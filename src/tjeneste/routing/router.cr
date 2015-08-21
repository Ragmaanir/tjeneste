module Tjeneste
  module Routing
    class Router

      class NoRouteFoundException < Exception
        def initialize(@request)
          super(to_s)
        end

        def to_s
          "No route found for: #{@request.method} #{@request.path}"
        end
      end

      getter :logger

      def initialize(root_node : Node, @logger = Logger.new(STDOUT) : Logger)
        # The root nodes matchers are not checked in #route, therefore
        # the passed root node has to be wrapped.
        @internal_root = InnerNode.new(children: [root_node])
      end

      def root
        @internal_root.children.first
      end

      def route(request) : Route?
        node = @internal_root
        node_path = [] of Node
        req = RequestState.new(request)

        while true
          case node
          when TerminalNode
            leaf = node as TerminalNode
            return Route.new(node_path, leaf.action)
          when InnerNode
            inner = node as InnerNode
            next_node = inner.children.find do |c|
              if res = c.match(req)
                req = res
              end
            end

            if next_node
              node_path << next_node
              node = next_node
            else
              return
            end
          else raise "Unknown node type"
          end
        end
      end

      def route!(request) : Route
        r = route(request)
        raise NoRouteFoundException.new(request) unless r
        r as Route
      end

    end
  end
end