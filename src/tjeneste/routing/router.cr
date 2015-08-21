module Tjeneste
  module Routing
    class Router

      getter :root, :logger

      def initialize(@root, @logger = Logger.new(STDOUT) : Logger)
      end

      def route(request) : Route?
        node = root
        node_path = [node]
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

    end
  end
end
