require "./node"

module Tjeneste
  module Routing
    class Route
      getter path : Array(Node)
      getter action : Action::AbstractLazyAction | Action::AbstractAction | HTTP::Handler | HttpBlock
      getter virtual_params : Hash(String, String)

      def initialize(@path, @action, @virtual_params)
      end

      def call_action(context : HTTP::Server::Context)
        case a = action
        when HTTP::Handler              then a.call(context)
        when Tjeneste::HttpBlock        then a.call(context)
        when Action::AbstractAction     then a.call_wrapper(context, self)
        when Action::AbstractLazyAction then a.call(context, self)
        else                                 raise("Invalid action type #{action.class}")
        end
      end
    end
  end
end
