module Tjeneste
  module Routing
    class RouterBuilder
      macro build(&block)
        b = Tjeneste::Routing::RouterBuilder.new
        b.build_block {{block}}
        Tjeneste::Routing::Router.new(b.root)
      end

      def initialize
        @root = InnerNode.new(constraints: [] of RoutingConstraint)
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
          code = <<-CRYSTAL
          macro #{v.id}(name, action)
            %constraints = [] of Tjeneste::Routing::RoutingConstraint

            %constraints << Tjeneste::Routing::HttpMethodConstraint.new(Tjeneste::Routing::Verb::#{verb.id})

            {% if name.is_a?(NamedTupleLiteral) %}
              %constraints << Tjeneste::Routing::BindingPathConstraint.new(
                name: {{name.keys.first.stringify}},
                regex: {{name.values.first}}
              )
            {% else %}
              %name = {{name}}
              %constraints << Tjeneste::Routing::PathConstraint.new(%name) unless %name.is_a?(String) && %name.to_s.empty?
            {% end %}

            append_child(Tjeneste::Routing::TerminalNode.new(
              constraints: %constraints,
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
          CRYSTAL
        %}
        {{code.id}}
      {% end %}

      macro mount(name, action)
        %name = {{name}}
        %constraints = [] of Tjeneste::Routing::RoutingConstraint
        %constraints << Tjeneste::Routing::PathConstraint.new(%name) unless %name.is_a?(String) && %name.to_s.empty?

        append_child(Tjeneste::Routing::TerminalNode.new(
          constraints: %constraints,
          action: {{action}},
          ignore_remainder: true
        ))
      end

      macro path(name, &block)
        %constraints = [] of Tjeneste::Routing::RoutingConstraint
        {% if name.is_a?(NamedTupleLiteral) %}
          %constraints << Tjeneste::Routing::BindingPathConstraint.new(
            name: {{name.keys.first.stringify}},
            regex: {{name.values.first}}
          )
        {% else %}
          %name = {{name}}
          %constraints << Tjeneste::Routing::PathConstraint.new(%name) unless %name.is_a?(String) && %name.to_s.empty?
        {% end %}
        %node = Tjeneste::Routing::InnerNode.new(constraints: %constraints)
        node_stack << %node
        build_block {{block}}
        node_stack.pop
        append_child(%node)
      end
    end
  end
end
