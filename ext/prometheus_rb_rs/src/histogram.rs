use std::collections::HashMap;

use magnus::{
    scan_args::{get_kwargs, scan_args},
    wrap, Error, Ruby, Value,
};
// use prometheus::HistogramVec;

#[wrap(class = "PrometheusRbRs::Histogram")]
pub struct Histogram {
    h: prometheus::HistogramVec,
}

impl Histogram {
    pub fn new(ruby: &Ruby, args: &[Value]) -> Result<Self, Error> {
        let args = scan_args::<_, (), (), (), _, ()>(args)?;
        let (name, help): (String, String) = args.required;
        let kw = get_kwargs::<
            _,
            (),
            (
                Option<Vec<f64>>,
                Option<Vec<String>>,
                Option<HashMap<String, String>>,
            ),
            (),
        >(args.keywords, &[], &["buckets", "labels", "preset_labels"])?;
        let (buckets, labels, preset_labels) = kw.optional;
        let mut opts = prometheus::HistogramOpts::new(name, help);
        if let Some(b) = buckets {
            opts = opts.buckets(b);
        }
        if let Some(preset) = preset_labels {
            opts = opts.const_labels(preset);
        }
        let l = labels.unwrap_or_else(|| vec![]);
        let label_refs: Vec<&str> = l.iter().map(|s| s.as_str()).collect();

        match prometheus::HistogramVec::new(opts, &label_refs) {
            Err(e) => return Err(Error::new(ruby.exception_standard_error(), e.to_string())),
            Ok(h) => Ok(Self { h }),
        }
    }

    pub fn observe(ruby: &Ruby, rb_self: &Histogram, args: &[Value]) -> Result<(), Error> {
        let args = scan_args::<_, (), (), (), _, ()>(args)?;
        let (value,): (f64,) = args.required;
        let kw = get_kwargs::<_, (), (Option<HashMap<String, String>>,), ()>(
            args.keywords,
            &[],
            &["labels"],
        )?;
        let (labels,) = kw.optional;
        let labels = labels.unwrap_or_else(|| HashMap::new());
        let converted: HashMap<&str, &str> = labels
            .iter()
            .map(|(k, v)| (k.as_str(), v.as_str()))
            .collect();

        match rb_self.h.get_metric_with(&converted) {
            Err(e) => Err(Error::new(ruby.exception_standard_error(), e.to_string())),
            Ok(metric) => Ok(metric.observe(value)),
        }
    }

    pub fn internal(&self) -> prometheus::HistogramVec {
        self.h.clone()
    }
}
