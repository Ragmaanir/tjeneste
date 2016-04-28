module Tjeneste
  module Routing
    class RequestState
      property request, path_index

      def initialize(@request : HTTP::Request, @path_index = 0)
      end

      def initialize(request : RequestState, @path_index = 0)
        @request = request.request
      end

      def path
        (request.path || "")[path_index..-1]
      end
    end
  end
end
