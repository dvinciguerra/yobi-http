# frozen_string_literal: true

require "base64"

module Yobi
  module CLI
    # Command-line argument utilities
    module Arguments
      class << self
        def http_method?(value)
          Yobi::Http::METHODS.include? value.upcase
        end

        def url(value)
          case value
          when %r{\Ahttps?://}
            value
          when /\A:\d+/
            "http://localhost#{value}"
          else
            "http://#{value}"
          end
        end

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def parse_data(args)
          args.select { |arg| arg.match?("^.*(=|:=|=@|:=@).*$") }.map.to_h do |arg|
            case arg
            when /:=@/
              arg.split(/:=@/, 2).map do |part|
                part = String(part)&.strip
                File.exist?(part) ? JSON.parse(File.read(part)) : part
              end
            when /:=/
              arg.split(/:=/, 2).map.with_index do |part, index|
                part = String(part)&.strip
                index.zero? ? part : JSON.parse(part)
              rescue JSON::ParserError => e
                warn "Error #{e}: #{part}"
                exit 1
              end
            when /=@/
              arg.split(/=@/, 2).map do |part|
                part = String(part)&.strip
                File.exist?(part) ? File.read(part)&.strip : part
              end
            else
              arg.split("=", 2).map(&:strip)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def parse_headers(args)
          { "Content-Type" => "application/json", "User-Agent" => "#{Yobi.name}/#{Yobi::VERSION}" }
            .merge(args.select do |arg|
                     arg.match?(/:/) && !arg.match?(/:=/)
                   end.map.to_h { |arg| arg.split(":", 2).map(&:strip) })
        end

        def auth_header(headers, options)
          raise ArgumentError, "Authentication credentials must be provided with --auth" unless options[:auth]

          auth_type = options.fetch(:auth_type, "basic")

          case auth_type.downcase
          when "basic"
            headers["Authorization"] = "Basic #{Base64.strict_encode64(options[:auth])}"
          when "bearer"
            headers["Authorization"] = "Bearer #{options[:auth]}"
          else
            warn "Unsupported authentication type: #{auth_type}"
            exit 1
          end
        end
      end
    end
  end
end
