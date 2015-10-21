module Tjeneste
  module Cookies
    class CookieSerializer
      # http://tools.ietf.org/html/rfc6265#page-13
      # http://tools.ietf.org/html/rfc2616#section-2.2
      TOKEN          = /([^\x0-\x31\x12]+)/
      COOKIE_NAME    = TOKEN
      COOKIE_OCTET   = /[\x21\x23-\x2B\x2D-\x3A\x3C-\x5B\x5D-\x7E]/
      COOKIE_OCTETS  = /(#{COOKIE_OCTET.source}+)/
      COOKIE_VALUE   = /#{COOKIE_OCTETS.source}|("#{COOKIE_OCTETS.source}")/
      COOKIE_PAIR    = /(#{COOKIE_NAME.source})=(#{COOKIE_VALUE.source})/
      CLIENT_COOKIE_HEADER = /\A#{COOKIE_PAIR.source}(\s*;\s*#{COOKIE_PAIR.source})*;?\z/

      # Agent -> Server
      def read(request : HTTP::Request) : Hash(String, String)
        cookie_header = request.headers["Cookie"].strip

        if !CLIENT_COOKIE_HEADER.match(cookie_header)
          return {} of String => String
        end

        pairs = cookie_header.split(";").map do |pair|
          name, value = pair.strip.split("=", 2)
          [name, value.gsub(/"/, "")] # Ignore quotes around cookie values
        end

        cookies = {} of String => String

        pairs.each do |pair|
          key, value = pair
          cookies[key] = value
        end

        cookies
      end

      # Server -> Agent
      def write(response : HTTP::Response, cookies)
      end
    end
  end
end
