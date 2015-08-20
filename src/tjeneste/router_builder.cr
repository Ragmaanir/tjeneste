module Tjeneste
  class RouterBuilder

    module BuilderDSL
      def path(name : String, &block) : Nil
        @node_stack << [] of Router::Node
        yield(self)
        children = @node_stack.pop
        @node_stack.last << Router::Node.new(
          matchers: [Router::PathMatcher.new("#{name}/")],
          children: children
        )
        nil
      end

      def get(name, block : -> Nil) : Nil
        node = Router::Node.new(
          matchers: [Router::PathMatcher.new(name)],
          action: block
        )
        @node_stack.last << node
        nil
      end
    end

    include BuilderDSL

    def self.build(&block : RouterBuilder -> Nil) : Router
      router = new(block).result
      router as Router
    end

    getter :result

    @node_stack = [[] of Router::Node]

    def initialize(block : RouterBuilder -> Nil)
      @node_stack = [[] of Router::Node]

      path("") do |r|
        block.call(self)
      end

      root_node = @node_stack.first.last
      @result = Router.new(root_node)
    end
  end
end
