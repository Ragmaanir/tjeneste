require "http/request"

# ### EXP 2

# module NestedCtx(T)
#   forward_missing_to original
#   getter :original

#   def initialize(@original : T)
#     @request = @original.request
#   end
# end

# class Ctx
#   getter :request

#   def initialize(@request : HTTP::Request)
#   end
# end

# class CCtx(T) < Ctx
#   include NestedCtx(T)

#   def initialize(@original : T)
#     @request = @original.request
#   end
# end

# class SCtx(T) < Ctx
#   include NestedCtx(T)

#   def initialize(@original : T)
#     @request = @original.request
#   end
# end

# class M
#   getter :successor
#   def initialize(@successor = nil)
#   end
#   def call(ctx) : HTTP::Response
#     case s = successor
#     when M then s.call(ctx)
#     when Nil then HTTP::Response.not_found
#     else raise "invalid param"
#     end
#   end
# end

# class CM < M
#   def call(ctx : T) : HTTP::Response
#     super(CCtx(T).new(ctx))
#     #super(ctx)
#   end
# end

# class SM < M
#   def call(ctx : T) : HTTP::Response
#     super(SCtx(T).new(ctx))
#     #super(ctx)
#   end
# end

# m = CM.new(SM.new)
# puts "a"
# r = HTTP::Request.new("GET", "")
# r.headers.merge!({"Cookie" => "test=1;"})
# ctx = Ctx.new(r)
# puts "b"
# m.call(ctx)
# puts "c"


### EXP 3

module NestedCtx(T)
  forward_missing_to original
  getter :original

  def initialize(@original : T)
    @request = @original.request
  end
end

class Ctx
  getter :request

  def initialize(@request : HTTP::Request)
  end
end

class CCtx(T) < Ctx
  include NestedCtx(T)

  def initialize(@original : T)
    @request = @original.request
  end
end

class SCtx(T) < Ctx
  include NestedCtx(T)

  def initialize(@original : T)
    @request = @original.request
  end
end

class Mid(T)
  getter :successor

  def initialize(@successor)
  end

  def call(ctx : T) : HTTP::Response
    puts "#{self.class.name}::call"
    successor.try { |s| s.call(ctx) } || HTTP::Response.new(404, "")
  end
end

class CM(T) < Mid(T)
  def call(ctx : T) : HTTP::Response
    super(CCtx(T).new(ctx))
  end
end

class SM(T) < Mid(T)
  def call(ctx : T) : HTTP::Response
    super(SCtx(T).new(ctx))
  end
end

class RM < Mid(Ctx)
  def call(ctx : T) : HTTP::Response
    super(ctx)
  end
end

class EP(T) < Mid(T)
  def initialize
  end

  def call(ctx : T) : HTTP::Response
    HTTP::Response.ok
  end
end

# m = RM.new(CM(Ctx).new(SM(CCtx(Ctx)).new(EP(SCtx(CCtx(Ctx))).new)))

# puts "a"
# r = HTTP::Request.new("GET", "")
# r.headers.merge!({"Cookie" => "test=1;"})
# ctx = Ctx.new(r)
# puts "b"
# m.call(ctx)
# puts "c"


# Cookies.new do |ctx|
#   Session.new do |ctx|
#     Endpoint.new().call(ctx)
#   end
# end

#RequestID(Cookies(Session(Authentication)))

# class RMW
#   def initialize(@successor)
#   end

#   def call(c)
#     @successor.call(c)
#   end
# end

### EXP 4

class CMW(C)
  CTX = CCtx

  def initialize(@successor)
  end
  def call(c : C)
    @successor.call(CCtx.new(c))
  end
end

class SMW(C)
  CTX = SCtx

  def initialize(@successor)
  end
  def call( c : C)
    @successor.call(SCtx.new(c))
  end
end

class EndP(C)
  def call(c : C)
    puts "success"
  end
end

m = CMW(Ctx).new(SMW(CCtx(Ctx)).new(EndP(SCtx(CCtx(Ctx))).new))

r = HTTP::Request.new("GET", "")
c = Ctx.new(r)
m.call(c)

module MDsl

  macro array_take(n, array)

    [{% for i, idx in array %}
      {% if idx < n %}
        {{i}},
      {% end %}
    {% end %}] of typeof({{array}})
  end

  p array_take(0, [1,2,3,4,5])

  macro nesgen(names)
    {% for name in names %}{{name}}({% end %}Ctx{% for name in names %}){% end %}
  end

  # macro nesgen(names)
  #   nesgen1({{names}}, 1, {{names.first}})
  # end

  macro nesgen1(names, i, exp)
    {% if i == names.length-1 %}
      {{exp}}({{names.last}})
    {% else %}
      nesgen1({{names}}, {{i+1}}, {{exp}}({{names[i]}}))
    {% end %}
  end

  # macro middleware(*middlewares)
  #   {% ctx = [] of Class %}
  #   {% for m in middlewares %}
  #     {% ctx << m %}
  #     {{m}}({{ctx.first}}::CTX
  #   {% end %}
  #   {% for m in middlewares %}
  #     )
  #   {% end %}
  # end

  macro middleware(middlewares)
    {% ctx = [] of Class %}
    {% for m in middlewares %}
      {% ctx << m %}{{m}}(nesgen({{ctx}})).new({% end %}{% for m in middlewares %}){% end %}
    {{debug()}}
  end

  # macro middleware1(ms)
  #   {% ctxs = [Ctx] of Class %}
  #   [
  #   {% for m, idx in ms %}
  #     {{m}}()
  #     {% ctxs << %}
  #   {% end %}
  #   ]
  # end

  macro map_contexts(ms)
    [{% for m in ms %}
      {{m}}::CTX,
    {% end %}]
  end

  macro pm(exp)
    puts "{{exp}} ===> #{({{exp}}).inspect}"
  end

  macro ident(x)
    {{x}}
  end

  macro m_test2(classes, ctx)
    {% a = Ctx %}
    {% for c in classes %}
      #{{c}}(nesgen({{ctx}}))
      {{c}}({{c}}::CTX(Ctx))
    {% end %}
  end

  macro m_test(i)
    {% if i < 3 %}
      [{{i}}] + [m_test({{i + 1}})]
    {% else %}
      {{i}}
    {% end %}
  end
end

include MDsl

pm nesgen([SCtx, CCtx]) # => SCtx(CCtx(Ctx+))
pm map_contexts([CMW, SMW]) # => [CCtx(T), SCtx(T)]

puts "-"*100
pm m_test(0)
pm m_test2([CMW], [CCtx])

#pm middleware([CMW, SMW, EndP])
#pm middleware1([CMW, SMW, EndP])


# CMW(Ctx).new(
#   SMW(CCtx(Ctx)).new(
#     EndP(SCtx(CCtx(Ctx)))
#   )
# )
