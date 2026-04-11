# frozen_string_literal: true

module Yobi
  module Renders
    # Render streaming (chunked) response chunks to the terminal as they arrive
    module Stream
      class << self
        # Called once when the response headers are received
        def render_headers(response, options = {})
          return unless options[:print]&.include?("H")

          if options[:raw]
            $stdout.puts "HTTP/#{response.http_version} #{response.code} #{response.message}"
            response.each_header { |key, value| $stdout.puts "#{key}: #{value}" }
            $stdout.puts
          else
            header_md = "# HTTP/#{response.http_version} #{response.code} #{response.message}\n\n" \
                        "```yaml\n" \
                        "#{response.each_capitalized.to_h.sort.map { |k, v| "#{k}: #{v}" }.join("\n")}\n" \
                        "```\n"
            $stdout.print TTY::Markdown.parse(header_md, color: :always)
          end

          $stdout.flush
        end

        # Called for each chunk received. Buffers partial lines across calls so
        # that JSON objects split across chunk boundaries are handled correctly.
        def render_chunk(chunk, options = {})
          return if chunk.nil? || chunk.empty?
          return unless options[:print]&.include?("B")

          if options[:raw]
            $stdout.print chunk
            $stdout.flush
            return
          end

          # Prepend any leftover incomplete line from the previous chunk
          data = (@line_buffer || "") + chunk
          @line_buffer = nil

          # ntfy.sh and many SSE/streaming APIs send newline-delimited JSON (ndjson).
          # Split on newlines; if the last segment doesn't end with "\n" it is incomplete.
          lines = data.split("\n", -1)

          # The last element is either "" (chunk ended with \n) or a partial line
          @line_buffer = lines.pop unless data.end_with?("\n")

          lines.each do |line|
            next if line.empty?

            parsed = begin
              JSON.parse(line)
            rescue JSON::ParserError
              nil
            end

            if parsed
              pretty = JSON.pretty_generate(parsed)
              md = "```json\n#{pretty}\n```\n"
              $stdout.print TTY::Markdown.parse(md, color: :always)
            else
              $stdout.puts line
            end

            $stdout.flush
          end
        end

        # Flush any remaining buffered line when the connection closes
        def flush_buffer(options = {})
          return unless @line_buffer && !@line_buffer.empty?
          return unless options[:print]&.include?("B")

          line = @line_buffer
          @line_buffer = nil

          parsed = begin
            JSON.parse(line)
          rescue JSON::ParserError
            nil
          end

          if parsed && !options[:raw]
            pretty = JSON.pretty_generate(parsed)
            md = "```json\n#{pretty}\n```\n"
            $stdout.print TTY::Markdown.parse(md, color: :always)
          else
            $stdout.puts line
          end

          $stdout.flush
        end
      end
    end
  end
end
