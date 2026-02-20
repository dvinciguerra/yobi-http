# frozen_string_literal: true

require "spec_helper"

RSpec.describe Yobi do
  describe "VERSION" do
    it { expect(Yobi.constants).to include(:VERSION) }

    it "follows semantic versioning format" do
      expect(Yobi::VERSION).to match(/^\d+\.\d+\.\d+$/)
    end
  end

  describe ".name" do
    it { expect(Yobi).to respond_to(:name) }
    it { expect(Yobi.name).to eq("yobi") }
  end

  describe ".description" do
    it { expect(Yobi).to respond_to(:description) }
    it { expect(Yobi.description).to eq("A simple HTTP client for testing APIs from the command line.") }
  end

  describe ".view" do
    it { expect(Yobi).to respond_to(:view) }

    it "loads a template by name" do
      expect(Yobi.view(:output).src).to include("HTTP/1.1")
    end

    it "raises an error if the template does not exist" do
      expect { Yobi.view("nonexistent") }.to raise_error(Errno::ENOENT)
    end
  end

  describe ".args" do
    it { expect(Yobi).to respond_to(:args) }
    it { expect(Yobi.args).to be(Yobi::CLI::Arguments) }
  end
end
