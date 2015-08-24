module Tjeneste
  module Routing

    alias Action = (HTTP::Request -> HTTP::Response)

    class RouterBuilder

      # Actually builds just the array of children and returns them as :result
      class NodeBuilder

        getter :result

        def self.build(block : NodeBuilder -> Nil)
          new(&block).result
        end

        def initialize(&block : NodeBuilder -> Nil)
          @result = [] of Node
          with self yield(self)
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
          def {{verb.id.downcase}}(name, target : T, *args) : Nil
            action(Verb::{{verb.id}}, name, target, *args)
          end
        {% end %}

        private def action(verb : Verb, name, target : T, *args) : Nil
          wrapper = ->(req : HTTP::Request){ target.new(*args).call(req) }
          action(verb, name, wrapper)
        end

        private def action(verb : Verb, name, target : Action) : Nil
          @result << TerminalNode.new(
            matchers: [PathMatcher.new(name), VerbMatcher.new(verb)],
            action: target
          )
          nil
        end

        def mount(name, middleware, *args) : Nil
          wrapper = ->(req : HTTP::Request){ middleware.new(*args).call(req) }
          @result << TerminalNode.new(
            matchers: [PathMatcher.new(name)],
            action: wrapper
          )
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
          matchers: [PathMatcher.new("/")],
          children: children
        )
        @result = Router.new(root_node)
      end

    end
  end
end
