require "./spec_helper"

module Tjeneste_Tests
  class EventSystemTest < Minitest::Test
    def test_subscribers_get_notified
      subscriber_called = false

      Tjeneste::EventSystem::Global.subscribe(Tjeneste::EventSystem, "test") do |cls, name, event|
        subscriber_called = true
      end

      assert !subscriber_called

      Tjeneste::EventSystem::Global.publish(Tjeneste::EventSystem, "test", Tjeneste::EventSystem::Event.new)

      assert subscriber_called
    end
  end
end
