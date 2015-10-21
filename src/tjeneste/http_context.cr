require "./cookies/cookie_serializer"

module Tjeneste
  class HttpContext
    getter :request

    def initialize(@request : HTTP::Request)
    end
  end

  module ContextDecorator(T)
    forward_missing_to original
    getter :original

    def initialize(@original : T)
      @request = @original.request
    end
  end

  class CookieContext(T) < HttpContext
    include ContextDecorator(T)

    def initialize(@original : T)
      @request = @original.request
    end

    def received_cookies
      @received_cookies ||= cookie_serializer.read(request)
    end

    def sent_cookies
      @sent_cookies ||= CookieJar.new
    end

    private def cookie_serializer
      Cookies::CookieSerializer.new
    end

  end

  class SessionContext(T) < HttpContext
    include ContextDecorator(T)

    def initialize(@original : T)
      @request = @original.request
    end

    def session
      original.received_cookies
    end
  end

end
