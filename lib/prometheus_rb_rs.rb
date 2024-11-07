# frozen_string_literal: true

require_relative "prometheus_rb_rs/version"
require_relative "prometheus_rb_rs/prometheus_rb_rs"

module PrometheusRbRs
  class Error < StandardError; end

  def self.registry
    @registry ||= Registry.new
  end
end
