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
        @internal_root = Node.new(children: [root_node])
      end

      def root
        @internal_root.children.first
      end

      def route(request) : Route?
        node = @internal_root
        node_path = [] of Node
        req = RequestState.new(request)

        while !node.leaf?
          next_node = node.children.find do |c|
            if res = c.match(req)
              req = res
            end
          end

          if next_node
            node = next_node
            node_path << node
          else
            break
          end
        end

        Route.new(node_path, node.action) if node.leaf?
      end

      def route!(request) : Route
        r = route(request)
        raise NoRouteFoundException.new(request) unless r
        r as Route
      end

    end
  end
end
