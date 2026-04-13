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

        def parse_query(args, _options)
          args.select { |arg| arg.match?(/::/) }.map.to_h { |arg| arg.split("::", 2).map(&:strip) }
        end

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def parse_data(args, _options = {})
          args.select { |arg| arg.match?("^.*(={1}|:=|=@|:=@).*$") }.map do |arg|
            case arg
            when /:=@/
              arg.split(":=@", 2).map do |part|
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
          end.compact.to_h
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def parse_headers(args, options = {})
          content_type = content_type_for options[:content_type]

          { "Content-Type" => content_type, "User-Agent" => "#{Yobi.name}/#{Yobi::VERSION}" }.merge(
            args
              .select { |arg| arg.match?(/:{1}/) && !arg.match?(/:=/) && !arg.match?(/::/) }
              .map.to_h { |arg| arg.split(/:{1}/, 2).map(&:strip) }
          )
        end

        def parse_raw_data(value)
          return nil if value.nil? || value.empty?

          if raw_data_file_path?(value)
            raise ArgumentError, "File not found: #{value}" unless File.exist?(value)

            ext = File.extname(value).downcase
            content_type = content_type_for_extension(ext)
            mode = content_type == "application/octet-stream" ? "rb" : "r"
            { body: File.read(value, mode: mode), content_type: content_type }
          else
            { body: value, content_type: nil }
          end
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

        private

        def content_type_for(value)
          case value
          when :form
            "application/x-www-form-urlencoded"
          when :multipart
            "multipart/form-data"
          when :xml
            "application/xml"
          when :binary
            "application/octet-stream"
          when :json, nil
            "application/json"
          else
            "application/json"
          end
        end

        def raw_data_file_path?(value)
          value.start_with?("./", "../", "/") || File.exist?(value)
        end

        def content_type_for_extension(ext)
          case ext
          when ".json"
            "application/json"
          when ".txt"
            "text/plain"
          when ".html", ".htm"
            "text/html"
          when ".xml"
            "application/xml"
          when ".csv"
            "text/csv"
          else
            "application/octet-stream"
          end
        end
      end
    end
  end
end
