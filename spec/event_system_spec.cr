require "./spec_helper"

describe Tjeneste::EventSystem do
  it "" do
    subscriber_called = false

    Tjeneste::EventSystem::Global.subscribe(Tjeneste::EventSystem, "test") do |cls, name, event|
      subscriber_called = true
    end

    assert !subscriber_called

    Tjeneste::EventSystem::Global.publish(Tjeneste::EventSystem, "test", Tjeneste::EventSystem::Event.new)

    assert subscriber_called
  end
end
