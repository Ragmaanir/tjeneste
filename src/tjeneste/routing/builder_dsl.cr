module Tjeneste
  module Routing
    module BuilderDSL

      def path(name : String, &block) : Nil
        @node_stack << [] of Node
        yield(self)
        children = @node_stack.pop
        @node_stack.last << Node.new(
          matchers: [PathMatcher.new("#{name}/")],
          children: children
        )
        nil
      end

      def get(name, block : HttpContext -> Nil) : Nil
        action(Verb::GET, name, block)
      end

      def post(name, block : HttpContext -> Nil) : Nil
        action(Verb::POST, name, block)
      end

      private def action(verb : Verb, name, block : HttpContext -> Nil) : Nil
        node = Node.new(
          matchers: [PathMatcher.new(name), VerbMatcher.new(verb)],
          action: block
        )
        @node_stack.last << node
        nil
      end

    end
  end
end
