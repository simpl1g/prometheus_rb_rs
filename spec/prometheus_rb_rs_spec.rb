# frozen_string_literal: true

RSpec.describe PrometheusRbRs do
  it "has a version number" do
    expect(PrometheusRbRs::VERSION).not_to be nil
  end

  let(:registry) { PrometheusRbRs::Registry.new }

  context "#registry" do
    it "can register a new counter" do
      counter = registry.register_counter("test_counter", "Test Counter")

      expect(counter).to be_a(PrometheusRbRs::Counter)
    end

    it "can register a new histogram" do
      histogram = registry.register_histogram("test_histogram", "Test Histogram", buckets: [0.1, 0.2, 0.3])

      expect(histogram).to be_a(PrometheusRbRs::Histogram)
    end

    it "raises error when wrong same name passed twice" do
      registry.register_counter("test_counter", "Test Counter")

      expect do
        registry.register_counter("test_counter", "Test Counter")
      end.to raise_error(StandardError).with_message("Duplicate metrics collector registration attempted")
    end
  end

  context "#histogram" do
    let(:histogram) { registry.register_histogram("test_histogram", "Test Histogram", buckets: [0.1, 0.2, 0.3]) }

    it "can observe histogram with float value" do
      histogram.observe(0.1)

      expect(registry.to_text).to eq <<~TEXT
        # HELP test_histogram Test Histogram
        # TYPE test_histogram histogram
        test_histogram_bucket{le="0.1"} 1
        test_histogram_bucket{le="0.2"} 1
        test_histogram_bucket{le="0.3"} 1
        test_histogram_bucket{le="+Inf"} 1
        test_histogram_sum 0.1
        test_histogram_count 1
      TEXT
    end

    it "can observe histogram with value large than max bucket" do
      histogram.observe(1)

      expect(registry.to_text).to eq <<~TEXT
        # HELP test_histogram Test Histogram
        # TYPE test_histogram histogram
        test_histogram_bucket{le="0.1"} 0
        test_histogram_bucket{le="0.2"} 0
        test_histogram_bucket{le="0.3"} 0
        test_histogram_bucket{le="+Inf"} 1
        test_histogram_sum 1
        test_histogram_count 1
      TEXT
    end

    it "can register histogram with default buckets" do
      histogram = registry.register_histogram("test_histogram", "Test Histogram")
      histogram.observe(0.01)

      expect(registry.to_text).to eq <<~TEXT
        # HELP test_histogram Test Histogram
        # TYPE test_histogram histogram
        test_histogram_bucket{le="0.005"} 0
        test_histogram_bucket{le="0.01"} 1
        test_histogram_bucket{le="0.025"} 1
        test_histogram_bucket{le="0.05"} 1
        test_histogram_bucket{le="0.1"} 1
        test_histogram_bucket{le="0.25"} 1
        test_histogram_bucket{le="0.5"} 1
        test_histogram_bucket{le="1"} 1
        test_histogram_bucket{le="2.5"} 1
        test_histogram_bucket{le="5"} 1
        test_histogram_bucket{le="10"} 1
        test_histogram_bucket{le="+Inf"} 1
        test_histogram_sum 0.01
        test_histogram_count 1
      TEXT
    end

    context "with custom labels" do
      let(:histogram) { registry.register_histogram("test_histogram", "Test Histogram", labels: %w[status], buckets: [0.1, 0.2, 0.3]) }

      it "can observe histogram with labels" do
        histogram.observe(0.1, labels: {"status" => "200"})

        expect(registry.to_text).to eq <<~TEXT
          # HELP test_histogram Test Histogram
          # TYPE test_histogram histogram
          test_histogram_bucket{status="200",le="0.1"} 1
          test_histogram_bucket{status="200",le="0.2"} 1
          test_histogram_bucket{status="200",le="0.3"} 1
          test_histogram_bucket{status="200",le="+Inf"} 1
          test_histogram_sum{status="200"} 0.1
          test_histogram_count{status="200"} 1
        TEXT
      end

      it "can observe histogram with multiple labels" do
        histogram.observe(0.1, labels: {"status" => "200"})
        histogram.observe(0.3, labels: {"status" => "200"})
        histogram.observe(0.4, labels: {"status" => "200"})
        histogram.observe(0.1, labels: {"status" => "404"})
        histogram.observe(0.5, labels: {"status" => "404"})
        histogram.observe(1, labels: {"status" => "404"})

        expect(registry.to_text).to eq <<~TEXT
          # HELP test_histogram Test Histogram
          # TYPE test_histogram histogram
          test_histogram_bucket{status="200",le="0.1"} 1
          test_histogram_bucket{status="200",le="0.2"} 1
          test_histogram_bucket{status="200",le="0.3"} 2
          test_histogram_bucket{status="200",le="+Inf"} 3
          test_histogram_sum{status="200"} 0.8
          test_histogram_count{status="200"} 3
          test_histogram_bucket{status="404",le="0.1"} 1
          test_histogram_bucket{status="404",le="0.2"} 1
          test_histogram_bucket{status="404",le="0.3"} 1
          test_histogram_bucket{status="404",le="+Inf"} 3
          test_histogram_sum{status="404"} 1.6
          test_histogram_count{status="404"} 3
        TEXT
      end
    end

    context "with preset labels" do
      let(:histogram) { registry.register_histogram("test_histogram", "Test Histogram", preset_labels: {"op" => "db"}) }

      it "can observe histogram with preset labels" do
        histogram.observe(0.1)

        expect(registry.to_text).to eq <<~TEXT
          # HELP test_histogram Test Histogram
          # TYPE test_histogram histogram
          test_histogram_bucket{op="db",le="0.005"} 0
          test_histogram_bucket{op="db",le="0.01"} 0
          test_histogram_bucket{op="db",le="0.025"} 0
          test_histogram_bucket{op="db",le="0.05"} 0
          test_histogram_bucket{op="db",le="0.1"} 1
          test_histogram_bucket{op="db",le="0.25"} 1
          test_histogram_bucket{op="db",le="0.5"} 1
          test_histogram_bucket{op="db",le="1"} 1
          test_histogram_bucket{op="db",le="2.5"} 1
          test_histogram_bucket{op="db",le="5"} 1
          test_histogram_bucket{op="db",le="10"} 1
          test_histogram_bucket{op="db",le="+Inf"} 1
          test_histogram_sum{op="db"} 0.1
          test_histogram_count{op="db"} 1
        TEXT
      end

      it "raises error when wrong number of args passed" do
        expect do
          histogram.observe(1, labels: {"status" => "200"})
        end.to raise_error(StandardError).with_message("Inconsistent label cardinality, expect 0 label values, but got 1")
      end
    end

    context "with preset and various labels" do
      let(:histogram) { registry.register_histogram("test_histogram", "Test Histogram", preset_labels: {"op" => "db"}, labels: ["status"]) }

      it "can observe histogram with all labels" do
        histogram.observe(1, labels: {"status" => "200"})

        expect(registry.to_text).to eq <<~TEXT
          # HELP test_histogram Test Histogram
          # TYPE test_histogram histogram
          test_histogram_bucket{op="db",status="200",le="0.005"} 0
          test_histogram_bucket{op="db",status="200",le="0.01"} 0
          test_histogram_bucket{op="db",status="200",le="0.025"} 0
          test_histogram_bucket{op="db",status="200",le="0.05"} 0
          test_histogram_bucket{op="db",status="200",le="0.1"} 0
          test_histogram_bucket{op="db",status="200",le="0.25"} 0
          test_histogram_bucket{op="db",status="200",le="0.5"} 0
          test_histogram_bucket{op="db",status="200",le="1"} 1
          test_histogram_bucket{op="db",status="200",le="2.5"} 1
          test_histogram_bucket{op="db",status="200",le="5"} 1
          test_histogram_bucket{op="db",status="200",le="10"} 1
          test_histogram_bucket{op="db",status="200",le="+Inf"} 1
          test_histogram_sum{op="db",status="200"} 1
          test_histogram_count{op="db",status="200"} 1
        TEXT
      end

      it "raises error when wrong number of labels passed" do
        expect do
          histogram.observe(0.1)
        end.to raise_error(StandardError).with_message("Inconsistent label cardinality, expect 1 label values, but got 0")
      end
    end

    it "raises error when wrong type passed" do
      expect { histogram.observe("a") }.to raise_error(TypeError)
    end

    it "raises error when wrong number of args passed" do
      expect { histogram.observe(1, 2) }.to raise_error(ArgumentError)
    end
  end

  context "#counter" do
    let(:counter) { registry.register_counter("test_counter", "Test Counter") }

    it "can increment counter with int value" do
      counter.observe(2)

      expect(registry.to_text).to eq <<~TEXT
        # HELP test_counter Test Counter
        # TYPE test_counter counter
        test_counter 2
      TEXT
    end

    it "can increment counter with float value" do
      counter.observe(3.0)

      expect(registry.to_text).to eq <<~TEXT
        # HELP test_counter Test Counter
        # TYPE test_counter counter
        test_counter 3
      TEXT
    end

    it "can increment counter with default" do
      counter.observe

      expect(registry.to_text).to eq <<~TEXT
        # HELP test_counter Test Counter
        # TYPE test_counter counter
        test_counter 1
      TEXT
    end

    it "raises error when wrong type passed" do
      expect { counter.observe("a") }.to raise_error(TypeError)
    end

    it "raises error when wrong number of args passed" do
      expect { counter.observe(1, 2) }.to raise_error(ArgumentError)
    end
  end
end
