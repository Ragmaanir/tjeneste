require "http/request"
require "secure_random"

module Tjeneste
  abstract class Middleware
    abstract def successor
  end

  module MiddlewareBuilder
    macro define_middleware_stack(hash)
      {% classes = hash.to_a %}
      nested_middleware_stack({{classes}}, 0)
    end

    macro nested_middleware_stack(array, i)
      {% cls = array[i][0] %}
      {% params = array[i][1] %}
      {% if i == 0 %}
        {% ctx = Tjeneste::HttpContext %}
      {% else %}
        {% ctx = array[i-1][0].id + "::Context" %}
      {% end %}

      {% if i == array.size - 1 %}
        {{cls}}({{ctx}}).new(*{{params}})
      {% else %}
        {{cls}}({{ctx}}).new(*{{params}}, nested_middleware_stack({{array}}, {{i+1}}))
      {% end %}
    end

  end

end
