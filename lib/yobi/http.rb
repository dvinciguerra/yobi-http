# frozen_string_literal: true

require "net/http"

module Yobi
  # Yobi Http behaviors and constants
  module Http
    METHODS = %w[GET POST PUT DELETE PATCH HEAD OPTIONS].freeze

    class << self
      # rubocop:disable Metrics/AbcSize
      def request(method, url, data: {}, headers: {}, options: {})
        @uri = URI(url)
        @options = options
        @method = method.capitalize

        Net::HTTP.start(@uri.host, @uri.port, use_ssl: @uri.scheme == "https") do |http|
          request_class = Net::HTTP.const_get(@method)
          request = request_class.new(@uri)

          headers.each { |key, value| request[key] = value }

          request.body = data.to_json unless data.empty?

          yield(http, request) if block_given?
        end
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
