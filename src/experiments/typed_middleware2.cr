
class Context
end

abstract class Middleware
  #getter :successor
  abstract def successor
end

class RequestIDMiddleware(C) < Middleware
  class Context < ::Context
    forward_missing_to original
    getter :original
    def initialize(@original : T)
    end

    def request_id
      123456
    end
  end

  getter :successor

  def initialize(@successor)
  end
  def call(c : C)
    @successor.call(Context.new(c))
  end
end

class CookieMiddleware(C) < Middleware
  class Context < ::Context
    forward_missing_to original
    getter :original
    def initialize(@original : T)
    end

    def cookies
      {"session" => "345asd"}
    end
  end

  getter :successor

  def initialize(@successor)
  end
  def call(c : C)
    @successor.call(Context.new(c))
  end
end

class SessionMiddleware(C) < Middleware
  class Context < ::Context
    forward_missing_to original
    getter :original
    def initialize(@original : T)
    end

    def user_id
      1337
    end
  end

  getter :successor

  def initialize(@successor)
  end
  def call(c : C)
    @successor.call(Context.new(c))
  end
end

class Endpoint(C)
  def call(c : C)
    p c.cookies
    p c.user_id
  end
end

class Endpoint2(C)
  def call(c : C)
    p c.cookies
    p c.user_id
    p c.request_id
  end
end

macro define_middleware_stack(*classes)
  {% for c, idx in classes %}
    {% if idx == 0 %}
      {{c}}(::Context).new(
    {% elsif idx == classes.length - 1 %}
      {{c}}({{classes[idx-1]}}::Context).new(
    {% else %}
      {{c}}({{classes[idx-1]}}::Context).new(
    {% end %}
  {% end %}
  {% for c, idx in classes %}
  )
  {% end %}
end

macro pm(exp)
  puts "{{exp}} ===> #{({{exp}}).inspect}"
end

ctx = Context.new

x = define_middleware_stack(RequestIDMiddleware, CookieMiddleware, SessionMiddleware, Endpoint2)
pm x
x.call(ctx)

# y = define_middleware_stack(CookieMiddleware, SessionMiddleware, Endpoint)
# pm typeof(y)
# y.call(ctx)

macro define_middleware_stack2(classes)
  {% for k,v in classes %}
    puts {{k}}
    {% if v.is_a?(Statement) %}
    puts {{v}}
    {% end %}
  {% end %}
end

x = define_middleware_stack2({
  RequestIDMiddleware => Tuple.new,
  CookieMiddleware => Tuple.new,
  SessionMiddleware => Tuple.new,
  Endpoint2 => Tuple.new
})

# pm x
# x.call(ctx)


# build_middleware_stack do
#   use RequestIDMiddleware
#   use CookieMiddleware, Settings.cookie_secret
#   use
# end

macro define_middleware_stack3(&block)
  {{yield}}
end

define_middleware_stack3 do
  RequestIDMiddleware
end
