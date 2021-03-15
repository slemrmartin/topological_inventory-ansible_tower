source 'https://rubygems.org'

plugin 'bundler-inject', '~> 1.1'
require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject") rescue nil

gem "activesupport", '~> 5.2.4.3'
gem "ansible_tower_client", "~> 0.21.0"
gem "cloudwatchlogger", "~> 0.2.1"
gem "concurrent-ruby"
gem "manageiq-loggers",   "~> 0.5.0"
gem "manageiq-messaging", "~> 1.0.0"
gem "more_core_extensions"
gem "optimist"
gem "prometheus_exporter", "~> 0.4.5"
gem "rake", ">= 12.3.3"
gem "rest-client", "~>2.0"

gem "receptor_controller-client", "~> 0.0.8"
gem "sources-api-client", "~> 3.0"
gem "topological_inventory-api-client", "~> 3.0"
gem "topological_inventory-ingress_api-client", "~> 1.0.1"
gem "topological_inventory-providers-common", "~> 3.0.0"
group :development, :test do
  gem "rspec"
  gem "rubocop", "~> 1.0.0"
  gem "rubocop-performance", "~> 1.8"
  gem "rubocop-rails", "~> 2.8"
  gem "simplecov", "~> 0.17.1"
  gem "timecop", "~> 0.9.1"
  gem "webmock"
end
