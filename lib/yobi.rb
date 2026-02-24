# frozen_string_literal: true

require "erb"

require "yobi/cli"
require "yobi/extensions"
require "yobi/http"
require "yobi/ui"
require "yobi/renders"
require "yobi/version"

# Yobi Http CLI client namespace
module Yobi
  # Standard Yobi error class
  class Error < StandardError; end

  class << self
    def name
      "yobi"
    end

    def description
      "A simple HTTP client for testing APIs from the command line."
    end

    # Load project templates
    def view(name)
      ERB.new(File.read(File.join(__dir__, "views/#{name}.md.erb")))
    end

    def request(...)
      Yobi::Http.request(...)
    end

    def args
      Yobi::CLI::Arguments
    end
  end
end
