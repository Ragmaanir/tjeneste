module Tjeneste
  module Routing
    class RoutingEndpoint(C)
      # class Context # FIXME Context = C
      #   forward_missing_to original
      #
      #   getter original
      #
      #   def initialize(@original : C)
      #   end
      # end

      getter router

      def initialize(@router : Routing::Router)
      end

      def call(context : C)
        route = router.route(context.request)

        if route
          action = route.action
          case action
          when HTTP::Handler then action.call(context)
          when Action        then action.call_wrapper(context)
          else                    raise
          end
        else
          context.response.status_code = 404
        end
      end
    end
  end
end
