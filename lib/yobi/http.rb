# frozen_string_literal: true

require "net/http"

module Yobi
  # Yobi Http behaviors and constants
  module Http
    METHODS = %w[GET POST PUT DELETE PATCH HEAD OPTIONS].freeze

    class << self
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def request(method, url, data: {}, headers: {}, options: {})
        @uri = URI(url)
        @options = options
        @method = method.capitalize

        Net::HTTP.start(@uri.host, @uri.port, use_ssl: @uri.scheme == "https") do |http|
          request_class = Net::HTTP.const_get(@method)
          request = request_class.new(@uri)

          if @options[:timeout]
            http.open_timeout = @options[:timeout]
            http.read_timeout = @options[:timeout]
          end

          headers.each { |key, value| request[key] = value }

          request.body = data.to_json unless data.empty?

          yield(http, request) if block_given?
        rescue Net::OpenTimeout, Net::ReadTimeout => e
          warn "Request timed out: #{e.message}"
          exit 1
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      # rubocop:disable Metrics/ParameterLists
      def follow_redirects(response, url, method, data, headers, options)
        return response unless response.is_a?(Net::HTTPRedirection)

        location = response["location"]
        warn "Redirected to #{location}" if options[:debug]
        new_url = URI.join(url, location).to_s

        request(method, new_url, data: data, headers: headers, options: options) do |new_http, new_request|
          response = new_http.request(new_request)
          return follow_redirects(response, new_url, method, data, headers, options)
        end
      end
      # rubocop:enable Metrics/ParameterLists

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def offline_mode(_request, options)
        Net::HTTP.class_eval do
          def connect; end
        end

        options[:verbose] = true

        Net::HTTPResponse.new("1.1", "200", "OK").tap do |response|
          response["Content-Type"] = "application/json"
          response["Access-Control-Allow-Credentials"] = true
          response["Access-Control-Allow-Origin"] = "*"
          response["Connection"] = "close"
          response["Date"] = Time.now.httpdate
          response["Server"] = "yobi-offline/#{Yobi::VERSION}"
          response["X-Powered-By"] = "Yobi/#{Yobi::VERSION}"

          response.body = JSON.pretty_generate({ message: "Offline mode enabled" })
          response.instance_variable_set(:@read, true)
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def download(request, http, options)
        http.request(request) do |response|
          total_bytes = response["Content-Length"]&.to_i
          progress = Yobi::UI::Progress.new(total_bytes)

          filename = options[:output] || File.basename(URI.parse(url).path)
          File.open(filename, "wb") do |file|
            response.read_body do |chunk|
              file.write(chunk)
              progress.increment(chunk.size)
            end
          end

          puts "\nDownload finished: #{filename}"
        end

        exit 0
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
    end
  end
end
