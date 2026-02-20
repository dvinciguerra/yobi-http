# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in yobi-http.gemspec
gemspec

group :development, :test do
  gem "irb"
  gem "rake", "~> 13.0"

  gem "bundler-audit", require: false
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rspec", require: false

  gem "solargraph", require: false
end

group :test do
  gem "rspec", "~> 3.0"
  gem "webmock", "~> 3.0"

  gem "simplecov", "~> 0.21"
  gem "simplecov-console", "~> 0.7"
end
