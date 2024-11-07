require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "prometheus_rb_rs", path: "../../"
end

require "prometheus_rb_rs"

registry = PrometheusRbRs::Registry.new
counter = registry.register_counter("test_counter", "Test Counter")
counter.observe

puts registry.values

# ruby script.rb
# Outputs:
# # HELP test_counter Test Counter
# # TYPE test_counter counter
# test_counter 1
