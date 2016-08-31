require "./spec_helper"

describe Tjeneste::EventSystem do
  class SubClass
  end

  test "subscribers get notified" do
    subscriber_called = false

    Tjeneste::EventSystem::Global.subscribe(SubClass, "test") do |cls, name, event|
      subscriber_called = true
    end

    assert !subscriber_called

    Tjeneste::EventSystem::Global.publish(SubClass, "test", Tjeneste::EventSystem::Event.new)

    assert subscriber_called
  end
end
