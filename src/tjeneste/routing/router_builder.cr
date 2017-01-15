# module Tjeneste
#   module Routing
#     class RouterBuilder
#       # def self.build(&block : NodeBuilder -> Nil) : Router
#       #   router = new(block).result
#       #   router.as(Router)
#       # end

#       macro build(&block)
#         builder = RouterBuilder.new.build {{block}}
#         builder.result
#       end

#       # getter result : Router

#       # def initialize(&block : NodeBuilder -> Nil)
#       #   children = NodeBuilder.build(&block)
#       #   root_node = InnerNode.new(
#       #     matchers: [PathMatcher.new("/")] of Matcher,
#       #     children: children
#       #   )
#       #   @result = Router.new(root_node)
#       # end

#       def result : Router
#         @result || raise
#       end

#       def build(&block)
#         children = NodeBuilder.build(&block)
#         root_node = InnerNode.new(
#           matchers: [PathMatcher.new("/")] of Matcher,
#           children: children
#         )
#         @result = Router.new(root_node)
#       end
#     end
#   end
# end

module Tjeneste
  module Routing
    class RouterBuilder
      macro build(&block)
        b = Tjeneste::Routing::RouterBuilder.new
        b.build_block {{block}}
        Tjeneste::Routing::Router.new(b.root)
      end

      def initialize
        # @root = InnerNode.new(matchers: [PathMatcher.new("/")])
        @root = InnerNode.new(matchers: [] of Matcher)
        @node_stack = [@root] of InnerNode
      end

      getter root : InnerNode
      getter node_stack : Array(InnerNode)

      def current_node
        @node_stack.last
      end

      def build_block(&block)
        with self yield
      end

      def append_child(node : Node)
        node.parent = current_node
        current_node.children << node
      end

      {% for verb in Verb.constants %}
        {%
          v = verb.downcase
          code = "
        macro #{v.id}(name, action)
          name = {{name}}

          matchers = [] of Tjeneste::Routing::Matcher
          matchers << Tjeneste::Routing::VerbMatcher.new(Tjeneste::Routing::Verb::#{verb.id})
          matchers << Tjeneste::Routing::PathMatcher.new(name) unless name.is_a?(String) && name.to_s.empty?

          append_child(Tjeneste::Routing::TerminalNode.new(
            matchers: matchers,
            action: {{action}}
          ))
        end

        macro #{v.id}(name, &action)
          #{v.id}({{name}}, ->({{action.args.first}} : HTTP::Server::Context) do
              {{action.body}}
              nil
            end
          )
        end
        "
        %}
        {{code.id}}
      {% end %}

      # macro post(name, &action)
      #   current_node.children << TerminalNode.new(
      #     matchers: [PathMatcher.new({{name}})],
      #     action: ->(ctx : HTTP::Server::Context){
      #       closure = ->(ctx : HTTP::Server::Context, &block : HTTP::Server::Context -> Nil) {
      #         yield(ctx)
      #       }
      #       closure.call(ctx) {{action}}
      #     }
      #   )
      # end

      macro mount(name, action)
        append_child(Tjeneste::Routing::TerminalNode.new(
          matchers: [Tjeneste::Routing::PathMatcher.new({{name}})],
          action: {{action}}
        ))
      end

      macro path(name, &block)
        %node = Tjeneste::Routing::InnerNode.new(matchers: [Tjeneste::Routing::PathMatcher.new({{name}})])
        node_stack << %node
        build_block {{block}}
        node_stack.pop
        append_child(%node)
      end
    end
  end
end
