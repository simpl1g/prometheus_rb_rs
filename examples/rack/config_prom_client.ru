# frozen_string_literal: true

require "prometheus"
require "prometheus/middleware/collector"
require "prometheus/middleware/exporter"

require "rack"
require "iodine"

Iodine.threads = 1
Iodine.workers = 1

RubyVM::YJIT.enable

use Prometheus::Middleware::Exporter
use Prometheus::Middleware::Collector
run lambda { |env| [200, {"content-type" => "text/plain"}, ["Hello, world!"]] }
