module Tjeneste
  abstract class Application
    def initialize(@server)
    end

    abstract def build_middleware : Middleware
  end
end
