module Tjeneste
  module Routing
    class RouterBuilder

      include BuilderDSL

      def self.build(&block : RouterBuilder -> Nil) : Router
        router = new(block).result
        router as Router
      end

      getter :result

      @node_stack = [[] of Node]

      def initialize(block : RouterBuilder -> Nil)
        @node_stack = [[] of Node]

        path("") do |r|
          block.call(self)
        end

        root_node = @node_stack.first.last
        @result = Router.new(root_node)
      end
    end
  end
end
