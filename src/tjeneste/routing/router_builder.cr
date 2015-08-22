module Tjeneste
  module Routing
    class RouterBuilder

      # Actually builds just the array of children and returns them as :result
      class NodeBuilder
        getter :result

        def self.build(block : NodeBuilder -> Nil)
          new(block).result
        end

        def initialize(block : NodeBuilder -> Nil)
          @result = [] of Node
          block.call(self)
        end

        def path(name, &block : NodeBuilder -> Nil) : Nil
          children = NodeBuilder.build(block)

          @result << InnerNode.new(
            matchers: [PathMatcher.new("#{name}/")],
            children: children
          )
          nil
        end

        {% for verb in Verb.constants %}
          def {{verb.id.downcase}}(name, block : HttpContext -> Nil) : Nil
            action(Verb::{{verb.id}}, name, block)
          end
        {% end %}

        private def action(verb : Verb, name, block : HttpContext -> Nil) : Nil
          node = TerminalNode.new(
            matchers: [PathMatcher.new(name), VerbMatcher.new(verb)],
            action: block
          )
          @result << node
          nil
        end
      end

      def self.build(&block : NodeBuilder -> Nil) : Router
        router = new(block).result
        router as Router
      end

      getter :result

      def initialize(block : NodeBuilder -> Nil)
        children = NodeBuilder.build(block)
        root_node = InnerNode.new(
          children: children
        )
        @result = Router.new(root_node)
      end

    end
  end
end
