source 'https://rubygems.org'

plugin 'bundler-inject', '~> 1.1'
require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject") rescue nil

gem "activesupport", "~> 5.2.2"
gem "concurrent-ruby"
gem "more_core_extensions"
gem "optimist"
gem "rake"
gem "manageiq-loggers", "~> 0.1.1"

gem "ansible_tower_client", "~> 0.19.0"

gem "topological_inventory-ingress_api-client", :git => "https://github.com/ManageIQ/topological_inventory-ingress_api-client-ruby", :branch => "master"

group :development, :test do
  gem "rspec"
  gem "simplecov"
end
