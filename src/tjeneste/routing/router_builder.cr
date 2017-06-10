module Tjeneste
  module Routing
    class RouterBuilder(App, Ctx)
      macro build(&block)
        %b = Tjeneste::Routing::RouterBuilder(Nil, Nil).new(nil)
        %b.build_block {{block}}
        Tjeneste::Routing::Router.new(%b.root)
      end

      macro build(app, app_cls, ctx_cls, &block)
        #%b = Tjeneste::Routing::RouterBuilder.new(context)
        #%b = Tjeneste::Routing::RouterBuilder.instantiate({ {context}})
        %b = Tjeneste::Routing::RouterBuilder({{app_cls}}, {{ctx_cls}}).new({{app}})
        %b.build_block {{block}}
        Tjeneste::Routing::Router.new(%b.root)
      end

      # def self.instantiate(context : C) forall C
      #   Tjeneste::Routing::RouterBuilder(C).new(context)
      # end

      def initialize(@app)
        @root = InnerNode.new(constraints: [] of RoutingConstraint)
        @node_stack = [@root] of InnerNode
      end

      getter root : InnerNode

      getter node_stack : Array(InnerNode)
      getter app : App

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

      def create_lazy_action(action)
        Tjeneste::Action::LazyAction(App, Ctx).new(app) { action.new(app) }
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

            %action = {{action}}

            %action = case %action
            when Class
              raise "err" unless %action <= Tjeneste::Action::AbstractAction
              #%a = %action.as(Tjeneste::Action::AbstractAction.class)
              #%a = typeof(%action.new)
              %a = %action
              #Tjeneste::Action::LazyAction(App, Ctx).new(app) { |app| %a.new(app) }
              create_lazy_action(%a)
            else
              %action
            end

            append_child(Tjeneste::Routing::TerminalNode.new(
              constraints: %constraints,
              action: %action
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
