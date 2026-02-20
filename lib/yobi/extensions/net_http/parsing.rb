# frozen_string_literal: true

module Net
  # Extend the Net::HTTPResponse class to add parsing methods
  class HTTPResponse
    # Parses the response body as JSON if the Content-Type is application/json, otherwise returns the raw body.
    #
    # @return [Object, String, nil] The parsed JSON object, raw body string, or nil if there is no body.
    def parsed_body
      return @parsed_body if instance_variable_defined?(:@parsed_body)

      if body && content_type&.include?("application/json")
        begin
          @parsed_body = JSON.parse(body)
        rescue JSON::ParserError
          @parsed_body = body
        end
      else
        @parsed_body = body
      end
    end
  end
end
