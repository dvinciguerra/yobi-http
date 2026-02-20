# frozen_string_literal: true

Dir.glob(File.expand_path("extensions/*.rb", __dir__)).sort.each do |path|
  require path
end
