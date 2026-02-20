# frozen_string_literal: true

require "spec_helper"

RSpec.describe Net::HTTPResponse do
  describe "#parsed_body" do
    subject(:response) do
      Yobi::Http.request(:get, "http://example.com") do |http, request|
        http.request(request)
      end
    end

    before do
      stub_request(:get, "http://example.com")
        .to_return(status: 200, body: '{"name": "John", "age": 30}', headers: { "Content-Type" => "application/json" })
    end

    it "parses JSON response bodies into Ruby objects" do
      expect(response.parsed_body).to eq({ "name" => "John", "age" => 30 })
    end

    context "when the response body is not valid JSON" do
      before do
        stub_request(:get, "http://example.com")
          .to_return(status: 200, body: "Not a JSON string", headers: { "Content-Type" => "application/json" })
      end

      it "returns the raw body string if JSON parsing fails" do
        expect(response.parsed_body).to eq("Not a JSON string")
      end
    end

    context "when the Content-Type is not application/json" do
      before do
        stub_request(:get, "http://example.com")
          .to_return(status: 200, body: "Just a plain text response", headers: { "Content-Type" => "text/plain" })
      end

      it "returns the raw body string if Content-Type is not application/json" do
        expect(response.parsed_body).to eq("Just a plain text response")
      end
    end
  end
end
