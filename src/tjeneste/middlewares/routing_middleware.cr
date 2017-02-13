module Tjeneste
  module Middlewares
    class RoutingMiddleware
      getter router : Routing::Router

      def initialize(@router)
      end

      def call(context : HTTP::Server::Context)
        route = router.route(context.request)

        if route
          route.call_action(context)
        else
          context.response.status_code = 404
        end
      end
    end
  end
end
