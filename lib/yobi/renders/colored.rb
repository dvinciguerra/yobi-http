# frozen_string_literal: true

module Yobi
  module Renders
    # Render a colored output of the request and response
    module Colored
      class << self
        def compile(request, response, options = {})
          body =
            JSON.pretty_generate(response.parsed_body) rescue response.body # rubocop:disable Style/RescueModifier

          view = Yobi.view(:output)
          TTY::Markdown.parse(view.result(binding), color: :always)
        end

        def render(request, response, options = {})
          view = compile(request, response, options)

          if options[:output]
            file_path = ::File.expand_path(options[:output], Dir.pwd)
            ::File.write(file_path, view, mode: "wb")
          else
            puts view
          end

          exit 0
        end
      end
    end
  end
end
