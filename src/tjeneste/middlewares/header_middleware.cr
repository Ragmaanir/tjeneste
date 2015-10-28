module Tjeneste
  module Middlewares
    class HeaderMiddleware(C) < Middleware

      class Context # FIXME Context = C
        forward_missing_to original
        getter original

        def initialize(@original : C)
        end
      end

      getter headers, successor

      def initialize(@headers : Hash(String, String), @successor)
      end

      def call(context : C) : HTTP::Response
        response = successor.call(Context.new(context))
        response.headers.merge!(headers)
        response
      end
    end
  end
end
