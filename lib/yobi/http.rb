# frozen_string_literal: true

require "json"
require "net/http"

module Yobi
  # Yobi Http behaviors and constants
  module Http
    METHODS = %w[GET POST PUT DELETE PATCH HEAD OPTIONS].freeze

    CONTENT_TYPES = {
      text: "text/plain",
      html: "text/html",
      form: "application/x-www-form-urlencoded",
      multipart: "multipart/form-data",
      xml: "application/xml",
      binary: "application/octet-stream",
      json: "application/json"
    }.freeze

    class << self
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/ParameterLists
      def request(method, url, data: {}, query: {}, headers: {}, options: {})
        @uri = URI(url)
        @uri.query = URI.encode_www_form(**query) unless query.empty?

        @options = options
        @method = method.capitalize

        Net::HTTP.start(@uri.host, @uri.port, use_ssl: @uri.scheme == "https") do |http|
          request_class = Net::HTTP.const_get(@method)
          request = request_class.new(@uri)

          if @options[:timeout]
            http.open_timeout = @options[:timeout]
            http.read_timeout = @options[:timeout]
          elsif @options[:stream]
            http.read_timeout = 0 # no timeout for long-lived streaming connections
          end

          headers.each { |key, value| request[key] = value }

          request.body = data.to_json unless data.empty?

          yield(http, request) if block_given?
        end
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        warn "Timeout: #{e.message}"
        exit 1
      rescue SocketError, Socket::ResolutionError => e
        warn "Network error: #{e.message}"
        exit 1
      rescue StandardError => e
        warn "Error: #{e.message}"
        exit 1
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/ParameterLists

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

      # rubocop:disable Metrics/AbcSize
      def offline_mode(_request, options)
        Net::HTTP.class_eval do
          def connect; end
        end

        options[:verbose] = true

        Net::HTTPResponse.new("1.1", "200", "OK").tap do |response|
          response["Content-Type"] = CONTENT_TYPES.fetch(options[:content_type], CONTENT_TYPES[:json])
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
      # rubocop:enable Metrics/AbcSize

      def stream(request, http, options)
        http.request(request) do |response|
          Yobi::Renders::Stream.render_headers(response, options)

          response.read_body do |chunk|
            Yobi::Renders::Stream.render_chunk(chunk, options)
          end

          Yobi::Renders::Stream.flush_buffer(options)
        end

        exit 0
      rescue Interrupt
        Yobi::Renders::Stream.flush_buffer(options)
        $stdout.puts
        exit 0
      end

      # rubocop:disable Metrics/AbcSize
      def download(request, http, options)
        http.request(request) do |response|
          url = request.uri.to_s
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
      # rubocop:enable Metrics/AbcSize
    end
  end
end
