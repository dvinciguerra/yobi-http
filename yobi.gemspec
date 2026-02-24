# frozen_string_literal: true

require_relative "lib/yobi/version"

Gem::Specification.new do |spec|
  spec.name = "yobi-http"
  spec.version = Yobi::VERSION

  spec.authors = ["Daniel Vinciguerra"]
  spec.email = ["daniel.vinciguerra@bivee.com.br"]

  spec.summary = "Yobi is a terminal tool to make HTTP requests and display responses in a friendly way inspired by HTTPie."
  spec.description = <<~DESCRIPTION
    Yobi is a terminal tool to make HTTP requests and display responses in a friendly way inspired by HTTPie.

    It allows you to easily send HTTP requests and view the responses in a human-readable format, making it easier
    to debug and test APIs from the command line.

    The main features of Yobi include:
      * Support for various HTTP methods (GET, POST, PUT, DELETE, etc.)
      * Customizable request headers and body
      * Pretty-printed responses with syntax highlighting
      * Download response content to a file
      * Low dependency and easy installation
  DESCRIPTION

  spec.license = "MIT"

  spec.homepage = "https://github.com/dvinciguerra/yobi-http"
  spec.required_ruby_version = ">= 3.0.0"

  # spec.metadata["allowed_push_host"] = "Set to your gem server 'https://example.com'"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/dvinciguerra/yobi-http"
  spec.metadata["changelog_uri"] = "https://github.com/dvinciguerra/yobi-http/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "base64", "~> 0.3"
  spec.add_dependency "tty-markdown", "~> 0.7"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
