use magnus::{
    scan_args::{get_kwargs, scan_args},
    wrap, Error, Ruby, Value,
};
use std::collections::HashMap;

#[wrap(class = "PrometheusRbRs::Counter")]
pub struct Counter {
    c: prometheus::CounterVec,
}

impl Counter {
    pub fn new(ruby: &Ruby, args: &[Value]) -> Result<Self, Error> {
        let args = scan_args::<_, (), (), (), _, ()>(args)?;
        let (name, help): (String, String) = args.required;
        let kw = get_kwargs::<_, (), (Option<Vec<String>>, Option<HashMap<String, String>>), ()>(
            args.keywords,
            &[],
            &["labels", "preset_labels"],
        )?;
        let (labels, preset_labels) = kw.optional;
        let mut opts = prometheus::Opts::new(name, help);
        if let Some(preset) = preset_labels {
            opts = opts.const_labels(preset);
        }
        let l = labels.unwrap_or_else(|| vec![]);
        let label_refs: Vec<&str> = l.iter().map(|s| s.as_str()).collect();

        match prometheus::CounterVec::new(opts, &label_refs) {
            Err(e) => return Err(Error::new(ruby.exception_standard_error(), e.to_string())),
            Ok(c) => Ok(Self { c }),
        }
    }

    pub fn observe(ruby: &Ruby, rb_self: &Counter, args: &[Value]) -> Result<(), Error> {
        let args = scan_args::<(), _, (), (), _, ()>(args)?;
        let (value,): (Option<f64>,) = args.optional;
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

        match rb_self.c.get_metric_with(&converted) {
            Err(e) => Err(Error::new(ruby.exception_standard_error(), e.to_string())),
            Ok(metric) => match value {
                Some(v) => Ok(metric.inc_by(v)),
                None => Ok(metric.inc()),
            },
        }
    }

    pub fn internal(&self) -> prometheus::CounterVec {
        self.c.clone()
    }
}
