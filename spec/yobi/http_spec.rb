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

    context "when making a POST request with data" do
      let(:meta) { [:post, "http://example.com"] }
      let(:result) { { status: 201, body: "Created" } }
      let(:arguments) { { body: { "name" => "John" }.to_json } }

      it { expect(response.code).to eq("201") }
      it { expect(response.body).to eq("Created") }
    end
  end
end
