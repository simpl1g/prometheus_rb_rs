# PrometheusRbRs

Thin wrapper around prometheus rust client

TODO:
- [ ] docs
    - [ ] yard
    - [ ] rust yard
- [x] examples
    - [x] simple
    - [x] rack middleware
- [ ] Thread/Fiber tests
- [ ] releases
    - [ ] prebuilt binaries
- [ ] metrics
    - [x] Counter
    - [x] Histogram
    - [ ] Gauge
    - [ ] Summary
- [x] formatters
    - [x] Text
- [x] middleware
- [ ] method profiler
- [ ] custom errors
- [ ] support forked servers?

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add prometheus_rb_rs
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install prometheus_rb_rs
```

## Usage

```ruby
registry = PrometheusRbRs::Registry.new
# or just `PrometheusRbRs.registry` for default one
counter = registry.register_counter("test_counter", "Test Counter")
counter.observe

puts registry.values
# HELP test_counter Test Counter
# TYPE test_counter counter
test_counter 2
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/simpl1g/prometheus_rb_rs.
