# frozen_string_literal: true

require "spec_helper"

RSpec.describe Yobi::Http do
  describe "METHODS" do
    it "includes standard HTTP methods" do
      expect(Yobi::Http::METHODS).to include("GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS")
    end
  end

  describe ".request" do
    subject(:response) { described_class.request(*meta) { |http, request| http.request(request) } }

    let(:meta) { [:get, "http://example.com"] }
    let(:result) { { status: 201, body: "Created" } }
    let(:arguments) { { body: {} } }

    before { stub_request(*meta).to_return(**result) }

    it { expect(Yobi::Http).to respond_to(:request) }

    context "when making a GET request" do
      let(:result) { { status: 200, body: "OK" } }
      let(:arguments) { { body: nil } }

      it { expect(response.code).to eq("200") }
      it { expect(response.body).to eq("OK") }
    end

    context "when making a POST request with a raw body" do
      let(:meta) { [:post, "http://example.com"] }
      let(:result) { { status: 201, body: "Created" } }

      it "sends the raw body directly without JSON encoding" do
        stub_request(:post, "http://example.com").with(body: '{"name":"Joe"}').to_return(status: 201, body: "Created")
        response = described_class.request("Post", "http://example.com", body: '{"name":"Joe"}') do |http, request|
          http.request(request)
        end
        expect(response.code).to eq("201")
      end
    end
  end
end
