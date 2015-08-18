module Tjeneste
  class Router
    class Node
      property :parent, :children, :segment

      def initialize(@children = [] of Node, @segment = nil : String?)
        @children.each{ |c| c.parent = self }
      end

      def root?
        parent == nil
      end

      def leaf?
        children.empty?
      end

      #def inspect
      #  "Node(children: #{children.map(&:inspect).join(",")}, segment: #{segment})"
      #end
    end

    class Route
      getter :path

      def initialize(@path : Array(Node))
      end
    end

    getter :root

    def initialize(@root)
    end

    def route(request) : Route?
      node = root
      node_path = [node]
      segments = request.path.split('/')

      while !node.leaf?
        segment = segments.shift

        next_node = node.children.find do |c|
          c.segment == segment
        end

        if next_node
          node = next_node
          node_path << node
        else
          break
        end
      end

      Route.new(node_path) if node.leaf?
    end
  end
end
