# frozen_string_literal: true

Dir.glob(File.expand_path("renders/*.rb", __dir__)).sort.each do |path|
  require path
end
