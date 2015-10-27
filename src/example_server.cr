require "./tjeneste"

class TestApp < Tjeneste::Application
  include Tjeneste::MiddlewareBuilder

  def build_middleware
    router = Tjeneste::Routing::RouterBuilder.build do |r|
      r.get "status", ->(req : HTTP::Request) {
        raise "Some error" if rand > 0.5
        HTTP::Response.new(200, "100% Ok")
      }
      r.get "", ->(req : HTTP::Request) {
        HTTP::Response.new 200, <<-HTML
          <html>
            <head>
              <script src="https://google.de/xyz.js">
              </script>
            </head>
            <body>
              <em>#{rand.to_s}</em>
            </body>
          </html>
        HTML
      }
    end

    define_middleware_stack({
      Tjeneste::TimingMiddleware => Tuple.new(),
      Tjeneste::ExceptionMiddleware => Tuple.new(),
      Tjeneste::HeaderMiddleware => Tuple.new({"Content-Security-Policy" => "script-src 'self'"}),
      Tjeneste::RoutingEndpoint => Tuple.new(router)
    })
  end

end

TestApp.new.run
