# frozen_string_literal: true

module PrometheusRbRs
  module Middleware
    # Exporter is a Rack middleware that provides a sample implementation of a
    # Prometheus HTTP exposition endpoint.
    #
    # By default it will export the state of the global registry and expose it
    # under `/metrics`. Use the `:registry` and `:path` options to change the
    # defaults.
    class Exporter
      attr_reader :app, :registry, :path

      CONTENT_TYPE = "text/plain"

      def initialize(app, options = {})
        @app = app
        @registry = options[:registry] || PrometheusRbRs.registry
        @path = options[:path] || "/metrics"
        @port = options[:port]
      end

      def call(env)
        if metrics_port?(env["SERVER_PORT"]) && env["PATH_INFO"] == @path
          [200, {"content-type" => CONTENT_TYPE}, [@registry.to_text]]
        else
          @app.call(env)
        end
      end

      def metrics_port?(request_port)
        @port.nil? || @port.to_s == request_port
      end
    end
  end
end
