# frozen_string_literal: true

require "prometheus_rb_rs"
require "prometheus_rb_rs/middleware/collector"
require "prometheus_rb_rs/middleware/exporter"

require "rack"
require "iodine"

Iodine.threads = 1
Iodine.workers = 1

RubyVM::YJIT.enable

use PrometheusRbRs::Middleware::Exporter
use PrometheusRbRs::Middleware::Collector
run lambda { |env| [200, {"content-type" => "text/plain"}, ["Hello, world!"]] }
