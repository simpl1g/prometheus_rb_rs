# frozen_string_literal: true

require "rack"
require "iodine"

Iodine.threads = 1
Iodine.workers = 1

RubyVM::YJIT.enable

run lambda { |env| [200, {"content-type" => "text/plain"}, ["Hello, world!"]] }
