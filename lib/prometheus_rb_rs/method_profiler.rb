# frozen_string_literal: true

module PrometheusRbRs
  class MethodProfiler
    def initialize
      @registry = PrometheusRbRs::Registry.new
      @histogram = @registry.register_histogram("method_duration_seconds", "Method duration in seconds")
    end

    def profile(method_name, &block)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = block.call
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
      @histogram.observe(duration)
      result
    end
  end
end
