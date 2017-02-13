module Tjeneste
  module Routing
    class RoutingState
      getter request : HTTP::Request
      getter path : String
      getter path_index : Int32
      getter segments : Array(String)
      getter virtual_params : Hash(String, String)

      def initialize(@request, @path_index = 0, @virtual_params = {} of String => String)
        @path = (request.path || "").sub(%r{/\z}, "")
        @segments = @path.split("/").skip(1)
        Kontrakt.precondition(path_index <= segments.size, "#{path_index} <= #{segments}")
      end

      def initialize(request : RoutingState, path_index = 0, virtual_params = {} of String => String)
        initialize(request.request, path_index, request.virtual_params.merge(virtual_params))
      end

      # def path
      #   (request.path || "")[path_index..-1]
      # end

      def prefix
        max = [0, path_index - 1].max
        segments[0..max]
      end

      def remaining
        if remaining_segments?
          segments[(path_index + 1)..-1]
        else
          [] of String
        end
      end

      def current_segment
        raise "Index #{path_index} too big for: #{segments}" if path_index >= segments.size
        segments[path_index]
      end

      def remaining_segments?
        segments.size > path_index
      end

      def inspect(io : IO)
        io << "RoutingState(#{prefix}, #{remaining})"
      end
    end
  end
end
