require "microtest"

require "../src/tjeneste"

include Tjeneste::Routing

include Microtest::DSL
Microtest.run!([
  Microtest::DescriptionReporter.new,
  Microtest::ErrorListReporter.new,
  Microtest::SlowTestsReporter.new,
  Microtest::SummaryReporter.new,
] of Microtest::Reporter)
