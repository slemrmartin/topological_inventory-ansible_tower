require "bundler/setup"
require "topological_inventory/ansible_tower/collector"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

spec_path = File.dirname(__FILE__)
Dir[File.join(spec_path, "support/**/*.rb")].each { |f| require f }

#
# You can add local requires to /lib/mock/require.dev.rb
#
require_dev_path = File.join(spec_path, "../lib", "require.dev.rb")
require require_dev_path if File.exist?(require_dev_path)
