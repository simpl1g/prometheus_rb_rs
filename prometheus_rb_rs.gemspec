# frozen_string_literal: true

require_relative "lib/prometheus_rb_rs/version"

Gem::Specification.new do |spec|
  spec.name = "prometheus_rb_rs"
  spec.version = PrometheusRbRs::VERSION
  spec.authors = ["Konstantin Ilchenko"]
  spec.email = ["konstantin@ilchenko.by"]

  spec.summary = "Thin Ruby wrapper around Prometheus Rust library"
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/simpl1g/prometheus_rb_rs"
  spec.required_ruby_version = ">= 3.1"
  spec.required_rubygems_version = ">= 3.3.11"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.each_line("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/prometheus_rb_rs/extconf.rb"]

  spec.add_dependency "rb_sys", "~> 0.9"
end
