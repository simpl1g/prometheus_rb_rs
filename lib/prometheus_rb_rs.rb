# frozen_string_literal: true

require_relative "prometheus_rb_rs/version"

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "prometheus_rb_rs/#{Regexp.last_match(1)}/prometheus_rb_rs"
rescue LoadError
  require "prometheus_rb_rs/prometheus_rb_rs"
end

module PrometheusRbRs
  class Error < StandardError; end

  def self.registry
    @registry ||= Registry.new
  end
end
