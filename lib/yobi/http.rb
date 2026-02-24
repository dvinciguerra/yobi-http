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

    end
  end
end
