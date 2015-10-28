module Tjeneste
  module Routing
    class RoutingEndpoint(C)

      class Context # FIXME Context = C
        forward_missing_to original

        getter original

        def initialize(@original : C)
        end
      end

      getter router

      def initialize(@router : Routing::Router)
      end

      def call(context : C)
        route = router.route(context.request)

        if route
          route.action.call(context.request)
        else
          HTTP::Response.not_found
        end
      end
    end
  end
end
