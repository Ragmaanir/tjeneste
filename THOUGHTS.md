
### Type Safety for Middlewares

What i want is

  use Tjeneste::Middlewares::TimingMiddleware
  use Tjeneste::Middlewares::ExceptionMiddleware
  use Tjeneste::Middlewares::HeaderMiddleware, {"Content-Security-Policy" => "script-src 'self'"}
  use Tjeneste::Middlewares::SessionMiddleware, key: "session_id"
  use Tjeneste::Routing::RoutingEndpoint, router: router

What i managed to do is


  define_middleware_stack({
    Tjeneste::Middlewares::TimingMiddleware    => Tuple.new,
    Tjeneste::Middlewares::ExceptionMiddleware => Tuple.new,
    Tjeneste::Middlewares::HeaderMiddleware    => Tuple.new({"Content-Security-Policy" => "script-src 'self'"}),
    Tjeneste::Middlewares::SessionMiddleware   => Tuple.new("session_id"),
    Tjeneste::Routing::RoutingEndpoint         => Tuple.new(router),
  })


### Endpoints

  class MyAction
    action(id : Int, name : String) do
    end
  end

  class MyAction
    def call(params : Parameters)
    end
  end

  module Topics
    action(:create, id : Int, name : String) do
    end
  end

### Coercion + Validation

  module Topics
    class Create
      params(
        id: Int32,
        special: Int32?
      )

      validate do
        id { id > 0 && id < 1024 && id % 2 == 0 }
      end

      validate do |params|
        # ...
      end

      action(id : Int) do
      end
    end
  end

  module Topics
    class Create
      class Params
        mapping(
          id: Int32,
          special: Int32,
          nested: TopicParams.mapping
        )

        validate do
          id      { id > 0 && id < 1024 && id % 2 == 0 }
          nested  { nested.valid? }
        end
      end
    end
  end
