# frozen_string_literal: true

require "webmock/rspec"

RSpec.configure do |config|
  # Enable WebMock
  config.before(:each) do
    WebMock.enable!
  end

  # Disable WebMock after each test to allow real HTTP connections if needed
  config.after(:each) do
    WebMock.disable!
  end
end
