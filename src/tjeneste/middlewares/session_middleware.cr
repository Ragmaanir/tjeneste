module Tjeneste
  module Middlewares
    class SessionMiddleware(C) < Middleware
      class Context
        forward_missing_to original
        getter original

        def initialize(@original : C, @session_id_name : String)
        end

        def session_id
          original.request.cookies[@session_id_name]?
        end
      end

      getter successor

      def initialize(@session_id_name : String, @successor)
      end

      def call(context : C) : HTTP::Response
        ctx = Context.new(context, @session_id_name)
        response = successor.call(ctx)

        if !ctx.session_id
          response.cookies << HTTP::Cookie.new(
            @session_id_name,
            generate_session_id,
            path: "/",
            expires: 1.day.from_now,
            http_only: true
          )
        end

        response
      end

      private def generate_session_id
        SecureRandom.hex
      end
    end
  end
end
