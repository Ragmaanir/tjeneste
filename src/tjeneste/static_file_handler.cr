require "uri"

module Tjeneste
  # A simple handler that lists directories and serves files under a given public directory.
  class StaticFileHandler
    include HTTP::Handler

    VALID_SYMBOLS    = Regex.escape("._-/?&")
    VALID_CHARS      = /[a-zA-Z0-9#{VALID_SYMBOLS}]/
    VALID_PATH_REGEX = %r{\A(#{VALID_CHARS})+\z}

    @public_dir : String

    # Creates a handler that will serve files in the given *public_dir*, after
    # expanding it (using `File#expand_path`).
    #
    # If *fallthrough* is `false`, this handler does not call next handler when
    # request method is neither GET or HEAD, then serves `405 Method Not Allowed`.
    # Otherwise, it calls next handler.
    def initialize(public_dir : String)
      @public_dir = File.expand_path(public_dir)
    end

    def call(context)
      if !%w(GET HEAD).includes?(context.request.method)
        context.response.status_code = 405
        context.response.headers.add("Allow", "GET, HEAD")
        return
      end

      original_path = context.request.path.not_nil!

      if original_path.ends_with?("/")
        # Directories are not listed
        context.response.status_code = 404
        return
      end

      request_path = URI.unescape(original_path)

      if !VALID_PATH_REGEX.match(request_path)
        context.response.status_code = 400
        return
      end

      expanded_path = File.expand_path(request_path, "/")

      file_path = File.join(@public_dir, expanded_path)

      if request_path != expanded_path
        redirect_to(context, expanded_path)
        return
      end

      if File.exists?(file_path)
        context.response.content_type = mime_type(file_path)
        context.response.content_length = File.size(file_path)
        File.open(file_path) do |file|
          IO.copy(file, context.response)
        end
      else
        call_next(context)
      end
    end

    private def redirect_to(context, url)
      context.response.status_code = 302

      url = URI.escape(url) { |b| URI.unreserved?(b) || b != '/' }
      context.response.headers.add "Location", url
    end

    private def mime_type(path)
      case File.extname(path)
      when ".txt"          then "text/plain"
      when ".htm", ".html" then "text/html"
      when ".css"          then "text/css"
      when ".js"           then "application/javascript"
      else                      "application/octet-stream"
      end
    end
  end
end
