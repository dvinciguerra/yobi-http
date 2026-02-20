if ENV["COVERAGE"]
  require "simplecov"
  require "simplecov-console"

  SimpleCov.root(File.expand_path("..", __dir__))

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
    [SimpleCov::Formatter::HTMLFormatter,
     SimpleCov::Formatter::Console]
  )
  SimpleCov.coverage_dir("coverage")

  SimpleCov.start do
    add_filter "/spec/"
    add_group "Lib", "lib"

    track_files "lib/**/*.rb"
  end

  SimpleCov.minimum_coverage 90
end

# puts "ROOT: #{SimpleCov.root}"
# puts "TRACKED: #{SimpleCov.tracked_files.inspect}"
# puts "LOADED BEFORE START: #{$LOADED_FEATURES.grep(/lib/).size}"

Dir[File.expand_path("../lib/**/*.rb", __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus unless ENV["CI"]

  if ENV["META"]
    config.example_status_persistence_file_path = "spec/examples.txt"
    config.profile_examples = 10
  end
  # config.warnings = true

  # if config.files_to_run.one?
  #   config.default_formatter = "doc"
  # end

  # config.order = :random
  # Kernel.srand config.seed

  config.after(:suite) do
    SimpleCov.result.format! if ENV["COVERAGE"]
  end
end

# load support configuration files
Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |f| require f }
