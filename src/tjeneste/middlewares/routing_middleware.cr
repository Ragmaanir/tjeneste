module Tjeneste
  module Middlewares
    class RoutingMiddleware
      getter router : Routing::Router

      def initialize(@router)
      end

      def call(context : HTTP::Server::Context)
        route = router.route(context.request)

        if route
          action = route.action
          case action
          when HTTP::Handler then action.call(context)
          when Action        then action.call_wrapper(context)
          else                    raise("Invalid action type")
          end
        else
          context.response.status_code = 404
        end
      end
    end
  end
end
