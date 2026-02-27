# frozen_string_literal: true

require "spec_helper"

RSpec.describe Yobi::CLI::Arguments do
  describe ".http_method?" do
    context "when given valid HTTP methods" do
      Yobi::Http::METHODS.each do |method|
        it "recognizes #{method} as a valid HTTP method" do
          expect(described_class.http_method?(method)).to be_truthy
        end

        it "is case-insensitive for #{method}" do
          expect(described_class.http_method?(method.downcase)).to be_truthy
        end
      end
    end

    context "when given invalid HTTP methods" do
      it "does not recognize FOO as a valid HTTP method" do
        expect(described_class.http_method?("Foo")).to be_falsey
      end
    end
  end

  describe ".url" do
    context "when given a URL that starts with http://" do
      it "returns the http URL unchanged if it looks completed and valid" do
        expect(described_class.url("http://example.com")).to eq("http://example.com")
      end

      it "returns the https URL unchanged if it looks completed and valid" do
        expect(described_class.url("https://example.com")).to eq("https://example.com")
      end
    end

    context "when given a URL that does not start with http://" do
      it "prepends http:// to URLs" do
        expect(described_class.url("example.com")).to eq("http://example.com")
      end
    end

    context "when given a URL that starts with :port" do
      it "returns a URL with http://localhost prepended" do
        expect(described_class.url(":3000")).to eq("http://localhost:3000")
      end
    end
  end

  describe ".parse_data" do
    it "parses key=value pairs into a hash" do
      args = ["name=John", "age=30", "city=New York"]

      expect(described_class.parse_data(args)).to eq({ "name" => "John", "age" => "30", "city" => "New York" })
    end

    it "ignores arguments that do not contain an equals sign" do
      args = ["name=John", "invalid_arg", "age=30"]

      expect(described_class.parse_data(args)).to eq({ "name" => "John", "age" => "30" })
    end

    context "when given an json string" do
      it "parses the json string into a hash" do
        args = ['data:={ "name": "John", "age": 30, "admin": false, "friends": ["Jane", "Doe"] }']

        expect(described_class.parse_data(args))
          .to eq({ "data" => { "name" => "John", "age" => 30, "admin" => false, "friends" => %w[Jane Doe] } })
      end

      it "raises an error if the json string is invalid" do
        args = ['data:={"name": "John", "age": 30, "city": "New York"'] # Missing closing brace

        expect { described_class.parse_data(args) }.to raise_error(SystemExit)
      end
    end

    context "when given a json file path" do
      let(:json_content) do
        {
          "title" => "Sample JSON",
          "description" => "This is a sample JSON file.",
          "version" => 1.0,
          "tags" => %w[sample json example],
          "metadata" => {
            "author" => "John Doe",
            "created" => "2024-06-01T12:00:00Z",
            "updated" => "2024-06-10T15:30:00Z"
          },
          "published" => true,
          "more_info" => nil
        }
      end

      before do
        File.write("sample.json", json_content.to_json)
      end

      after do
        File.delete("sample.json") if File.exist?("sample.json")
      end

      it "parses the json file content into a hash" do
        args = ["data:=@sample.json"]

        expect(described_class.parse_data(args)).to eq({ "data" => json_content })
      end
    end
  end

  describe ".parse_headers" do
    it "parses key:value pairs into a headers hash" do
      args = ["Content-Type: text/http", "User-Agent: Yobi/1.0"]

      expect(described_class.parse_headers(args))
        .to eq({ "Content-Type" => "text/http", "User-Agent" => "Yobi/1.0" })
    end

    it "includes default headers" do
      args = []

      expect(described_class.parse_headers(args))
        .to eq({ "Content-Type" => "application/json", "User-Agent" => "#{Yobi.name}/#{Yobi::VERSION}" })
    end
  end

  describe ".auth_header" do
    it "raises an error if auth credentials are missing" do
      expect { described_class.auth_header({}, {}) }.to raise_error(ArgumentError)
    end

    it "adds a Basic Authorization header when auth_type is basic" do
      headers = {}
      options = { auth: "user:pass", auth_type: "basic" }

      described_class.auth_header(headers, options)
      expect(headers["Authorization"]).to eq("Basic #{Base64.strict_encode64("user:pass")}")
    end

    it "adds a Bearer Authorization header when auth_type is bearer" do
      headers = {}
      options = { auth: "mytoken", auth_type: "bearer" }

      described_class.auth_header(headers, options)
      expect(headers["Authorization"]).to eq("Bearer mytoken")
    end

    it "exits with an error for unsupported auth types" do
      headers = {}
      options = { auth: "mytoken", auth_type: "unsupported" }

      expect { described_class.auth_header(headers, options) }.to raise_error(SystemExit)
    end
  end
end
