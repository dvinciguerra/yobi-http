# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "yobi/http"

# Yobi Http CLI client namespace
module Yobi
  # Standard Yobi error class
  class Error < StandardError; end

  # Yobi gem version
  VERSION = "0.1.0"


  def self.name
    "yobi"
  end

  def self.description
    "A simple HTTP client for testing APIs from the command line."
  end

  # Load project templates
  def self.view(name)
    File.read(File.join(__dir__, "views/#{name}.md.erb"))
  end
end
