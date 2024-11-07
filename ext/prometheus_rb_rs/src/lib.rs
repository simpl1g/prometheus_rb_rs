mod counter;
mod histogram;

use magnus::{function, method, prelude::*, wrap, Error, Ruby, Value};
use prometheus::{core::Collector, Encoder, Registry, TextEncoder};
use std::cell::RefCell;

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("PrometheusRbRs")?;
    module.define_error("Error", ruby.exception_standard_error())?;
    // PrometheusRbRs::Registry
    let class = module.define_class("Registry", ruby.class_object())?;
    class.define_singleton_method("new", function!(MutPrometheusRbRs::new, 0))?;
    class.define_method(
        "register_counter",
        method!(MutPrometheusRbRs::register_counter, -1),
    )?;
    class.define_method(
        "register_histogram",
        method!(MutPrometheusRbRs::register_histogram, -1),
    )?;
    class.define_method("values", method!(MutPrometheusRbRs::values, 0))?;
    // PrometheusRbRs::Histogram
    let class = module.define_class("Histogram", ruby.class_object())?;
    class.define_singleton_method("new", function!(histogram::Histogram::new, -1))?;
    class.define_method("observe", method!(histogram::Histogram::observe, -1))?;
    // PrometheusRbRs::Counter
    let class = module.define_class("Counter", ruby.class_object())?;
    class.define_singleton_method("new", function!(counter::Counter::new, -1))?;
    class.define_method("observe", method!(counter::Counter::observe, -1))?;

    Ok(())
}

struct PrometheusRbRs {
    registry: prometheus::Registry,
}

#[wrap(class = "PrometheusRbRs::Registry")]
struct MutPrometheusRbRs(RefCell<PrometheusRbRs>);

impl MutPrometheusRbRs {
    pub fn new() -> Self {
        let registry = Registry::new();
        Self(RefCell::new(PrometheusRbRs { registry }))
    }

    pub fn register_counter(
        ruby: &Ruby,
        rb_self: &MutPrometheusRbRs,
        args: &[Value],
    ) -> Result<counter::Counter, Error> {
        let counter = counter::Counter::new(ruby, args)?;
        rb_self.register(Box::new(counter.internal()), ruby)?;

        Ok(counter)
    }

    pub fn register_histogram(
        ruby: &Ruby,
        rb_self: &MutPrometheusRbRs,
        args: &[Value],
    ) -> Result<histogram::Histogram, Error> {
        let hist = histogram::Histogram::new(ruby, args)?;
        rb_self.register(Box::new(hist.internal()), ruby)?;

        Ok(hist)
    }

    pub fn values(ruby: &Ruby, rb_self: &MutPrometheusRbRs) -> Result<String, Error> {
        let encoder = TextEncoder::new();
        let mut buffer = vec![];
        let metric_families = rb_self.0.borrow().registry.gather();
        encoder.encode(&metric_families, &mut buffer).unwrap();

        String::from_utf8(buffer)
            .map_err(|e| Error::new(ruby.exception_encoding_error(), e.to_string()))
    }

    fn register(&self, metric: Box<dyn Collector>, ruby: &Ruby) -> Result<(), Error> {
        return match self.0.borrow_mut().registry.register(metric) {
            Ok(_) => Ok(()),
            Err(e) => Err(Error::new(ruby.exception_standard_error(), e.to_string())),
        };
    }
}
