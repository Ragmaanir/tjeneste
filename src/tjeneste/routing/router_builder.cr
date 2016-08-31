module Tjeneste
  module Routing
    alias Action = (HTTP::Server::Context -> Nil)

    class RouterBuilder
      # Actually builds just the array of children and returns them as :result
      class NodeBuilder
        getter result : Array(Node)

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
            matchers: [PathMatcher.new("#{name}/")] of Matcher,
            children: children
          )
          nil
        end

        {% for verb in Verb.constants %}
          def {{verb.id.downcase}}(name, target : T, *args) : Nil
            action(Verb::{{verb.id}}, name, target, *args)
          end
        {% end %}

        private def action(verb : Verb, name, target : Action) : Nil
          @result << TerminalNode.new(
            matchers: [PathMatcher.new(name), VerbMatcher.new(verb)] of Matcher,
            action: target
          )
          nil
        end

        private def action(verb : Verb, name, target : HTTP::Server::Context -> T) : Nil
          @result << TerminalNode.new(
            matchers: [PathMatcher.new(name), VerbMatcher.new(verb)] of Matcher,
            action: ->(ctx : HTTP::Server::Context) { target.call(ctx); nil }
          )
          nil
        end

        private def action(verb : Verb, name, target : T, *args) : Nil
          wrapper = ->(ctx : HTTP::Server::Context) { target.new(*args).call(ctx) }
          action(verb, name, wrapper)
        end

        def mount(name, middleware, *args) : Nil
          wrapper = ->(ctx : HTTP::Server::Context) { middleware.new(*args).call(ctx); nil }
          @result << TerminalNode.new(
            matchers: [PathMatcher.new(name)] of Matcher,
            action: wrapper
          )
          nil
        end
      end

      def self.build(&block : NodeBuilder -> Nil) : Router
        router = new(block).result
        router.as(Router)
      end

      getter result

      def initialize(block : NodeBuilder -> Nil)
        children = NodeBuilder.build(block)
        root_node = InnerNode.new(
          matchers: [PathMatcher.new("/")] of Matcher,
          children: children
        )
        @result = Router.new(root_node)
      end
    end
  end
end
