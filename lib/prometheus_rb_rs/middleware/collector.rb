require "benchmark"

module PrometheusRbRs
  module Middleware
    # Collector is a Rack middleware that provides a sample implementation of a
    # HTTP tracer.
    #
    # By default metrics are registered on the global registry. Set the
    # `:registry` option to use a custom registry.
    #
    # By default metrics all have the prefix "http_server". Set
    # `:metrics_prefix` to something else if you like.
    #
    # The request counter metric is broken down by code, method and path.
    # The request duration metric is broken down by method and path.
    class Collector
      def initialize(app, options = {})
        @app = app
        @registry = options[:registry] || PrometheusRbRs.registry
        @metrics_prefix = options[:metrics_prefix] || "http_server"

        init_request_metrics
        init_exception_metrics
      end

      def call(env)
        response = nil
        duration = Benchmark.realtime { response = @app.call(env) }
        record(env, response.first.to_s, duration)

        response
      rescue => exception
        @exceptions.observe(labels: {"exception" => exception.class.name})
        raise
      end

      protected

      def init_request_metrics
        @requests = @registry.register_counter(
          "#{@metrics_prefix}_requests_total",
          "The total number of HTTP requests handled by the Rack application.",
          labels: %w[code method path]
        )
        @durations = @registry.register_histogram(
          "#{@metrics_prefix}_request_duration_seconds",
          "The HTTP response duration of the Rack application.",
          labels: %w[method path]
        )
      end

      def init_exception_metrics
        @exceptions = @registry.register_counter(
          "#{@metrics_prefix}_exceptions_total",
          "The total number of exceptions raised by the Rack application.",
          labels: ["exception"]
        )
      end

      def record(env, code, duration)
        path = generate_path(env)

        counter_labels = {
          "code" => code,
          "method" => env["REQUEST_METHOD"].downcase,
          "path" => path
        }

        duration_labels = {
          "method" => env["REQUEST_METHOD"].downcase,
          "path" => path
        }

        @requests.observe(labels: counter_labels)
        @durations.observe(duration, labels: duration_labels)
      rescue
      end

      def generate_path(env)
        full_path = [env["SCRIPT_NAME"], env["PATH_INFO"]].join

        strip_ids_from_path(full_path)
      end

      def strip_ids_from_path(path)
        path
          .gsub(%r{/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(?=/|$)}, '/:uuid\\1')
          .gsub(%r{/\d+(?=/|$)}, '/:id\\1')
      end
    end
  end
end
