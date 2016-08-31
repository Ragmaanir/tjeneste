require "microtest"

require "../src/tjeneste"

include Tjeneste::Routing

include Microtest::DSL
Microtest.run!
