

define_middleware_stack([
  RequestIDMiddleware.new,
  HeaderMiddleware.new,
  SessionMiddleware.new,
  RoutingEndpoint.new do
    path :topics do
      get
    end
  end
])
