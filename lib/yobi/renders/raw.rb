# frozen_string_literal: true

module Yobi
  module Renders
    # Render a raw output of the request and response
    module Raw
      class << self
        def compile(request, response, options = {})
          arguments request: request, response: response, options: options

          buffer.tap do
            compile_request
            compile_response
          end
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

        private

        attr_reader :request, :response, :options

        def buffer
          @buffer ||= String.new
        end

        def arguments(**args)
          @request = args[:request]
          @response = args[:response]
          @options = args[:options] || {}
        end

        def show_header?(request_or_response)
          options[:print].include?(request_or_response.is_a?(Net::HTTPResponse) ? "H" : "h")
        end

        def show_body?(request_or_response)
          options[:print].include?(request_or_response.is_a?(Net::HTTPResponse) ? "B" : "b")
        end

        def compile_request
          compile_request_header
          compile_request_body

          buffer << "\n" * 2 if show_header?(request) || show_body?(request)
        end

        def compile_request_header
          return unless show_header? request

          buffer << "#{request.method} #{request.path} HTTP/1.1 \n"
          request.each_capitalized.sort.each do |key, value|
            buffer << "#{key}: #{value}\n"
          end
          buffer << "\n"
        end

        def compile_request_body
          return unless show_body?(request) && request.body && !request.body.empty?

          buffer << "#{JSON.pretty_generate(request.parsed_body) rescue request.body}\n" # rubocop:disable Style/RescueModifier
        end

        def compile_response
          compile_response_header
          compile_response_body
        end

        def compile_response_header
          return unless show_header? response

          buffer << "HTTP/#{response.http_version} #{response.code} #{response.message}\n"
          response.each_header { |key, value| buffer << "#{key}: #{value}\n" }
          buffer << "\n"
        end

        def compile_response_body
          return unless response.body && !response.body.empty? && options[:print].include?("B")

          buffer << "#{JSON.pretty_generate(response.parsed_body)}\n"
        end
      end
    end
  end
end
