module Tjeneste
  module Routing
    class RoutingState
      getter request : HTTP::Request
      getter path_index : Int32

      def initialize(@request, @path_index = 0)
        @path = request.path || ""
      end

      def initialize(request : RoutingState, path_index = 0)
        initialize(request.request, path_index)
      end

      # def path
      #   (request.path || "")[path_index..-1]
      # end

      def segments
        @path.split("/")[1..-1]
      end

      def current_segment
        segments[path_index]
      end
    end
  end
end
