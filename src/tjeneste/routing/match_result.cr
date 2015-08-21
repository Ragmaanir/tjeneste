module Tjeneste
  module Routing
    abstract class MatchResult
      abstract def success? : Bool
    end

    class MatchSuccess < MatchResult
      property :request

      def initialize(@request : RequestState)
      end

      def success?
        true
      end
    end

    class MatchFailure < MatchResult
      property :error

      def initialize(@error)
      end

      def success?
        false
      end
    end
  end
end
