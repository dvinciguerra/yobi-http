# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

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

  describe ".parse_raw_data" do
    context "when given an inline string" do
      it "returns the string as the body with no content_type" do
        result = described_class.parse_raw_data('{"name":"Joe"}')
        expect(result).to eq({ body: '{"name":"Joe"}', content_type: nil })
      end

      it "returns nil when value is nil" do
        expect(described_class.parse_raw_data(nil)).to be_nil
      end

      it "returns nil when value is empty" do
        expect(described_class.parse_raw_data("")).to be_nil
      end
    end

    context "when given a file path" do
      let(:tmpdir) { Dir.mktmpdir }

      after { FileUtils.remove_entry(tmpdir) }

      it "reads a .json file and infers application/json content-type" do
        path = File.join(tmpdir, "data.json")
        File.write(path, '{"name":"Joe"}')
        result = described_class.parse_raw_data(path)
        expect(result[:body]).to eq('{"name":"Joe"}')
        expect(result[:content_type]).to eq("application/json")
      end

      it "reads a .txt file and infers text/plain content-type" do
        path = File.join(tmpdir, "data.txt")
        File.write(path, "hello world")
        result = described_class.parse_raw_data(path)
        expect(result[:body]).to eq("hello world")
        expect(result[:content_type]).to eq("text/plain")
      end

      it "reads a .html file and infers text/html content-type" do
        path = File.join(tmpdir, "data.html")
        File.write(path, "<h1>Hello</h1>")
        result = described_class.parse_raw_data(path)
        expect(result[:body]).to eq("<h1>Hello</h1>")
        expect(result[:content_type]).to eq("text/html")
      end

      it "reads a .htm file and infers text/html content-type" do
        path = File.join(tmpdir, "data.htm")
        File.write(path, "<p>Hi</p>")
        result = described_class.parse_raw_data(path)
        expect(result[:content_type]).to eq("text/html")
      end

      it "reads a .xml file and infers application/xml content-type" do
        path = File.join(tmpdir, "data.xml")
        File.write(path, "<root/>")
        result = described_class.parse_raw_data(path)
        expect(result[:body]).to eq("<root/>")
        expect(result[:content_type]).to eq("application/xml")
      end

      it "reads a .csv file and infers text/csv content-type" do
        path = File.join(tmpdir, "data.csv")
        File.write(path, "a,b\n1,2")
        result = described_class.parse_raw_data(path)
        expect(result[:body]).to eq("a,b\n1,2")
        expect(result[:content_type]).to eq("text/csv")
      end

      it "reads a binary file and uses application/octet-stream content-type" do
        path = File.join(tmpdir, "data.bin")
        File.write(path, "\x00\x01\x02", mode: "wb")
        result = described_class.parse_raw_data(path)
        expect(result[:content_type]).to eq("application/octet-stream")
      end

      it "uses a relative path starting with ./ to detect a file" do
        path = "./#{File.basename(tmpdir)}_relative_test.json"
        File.write(path, '{"x":1}')
        result = described_class.parse_raw_data(path)
        expect(result[:content_type]).to eq("application/json")
      ensure
        File.delete(path) if File.exist?(path)
      end

      it "raises ArgumentError when the file does not exist" do
        expect { described_class.parse_raw_data("./nonexistent_file.json") }.to raise_error(ArgumentError, /File not found/)
      end
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
