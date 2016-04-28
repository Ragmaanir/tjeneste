require "./spec_helper"

module Tjeneste_Tests
  class SubClass
  end

  class EventSystemTest < Minitest::Test
    def test_subscribers_get_notified
      subscriber_called = false

      Tjeneste::EventSystem::Global.subscribe(SubClass, "test") do |cls, name, event|
        subscriber_called = true
      end

      assert !subscriber_called

      Tjeneste::EventSystem::Global.publish(SubClass, "test", Tjeneste::EventSystem::Event.new)

      assert subscriber_called
    end
  end
end
