# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"
require "bundler/gem_tasks"
require "rake/testtask"
require "rake/extensiontask"

task build: :compile
task default: :test
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"].exclude(/docs_test/)
end

Rake::TestTask.new("test:docs") do |t|
  t.libs << "test"
  t.pattern = "test/docs_test.rb"
end

platforms = [
  "x86_64-linux",
  "x86_64-linux-musl",
  "aarch64-linux",
  "aarch64-linux-musl",
  "x86_64-darwin",
  "arm64-darwin",
  "x64-mingw-ucrt"
]

gemspec = Bundler.load_gemspec("prometheus_rb_rs.gemspec")
Rake::ExtensionTask.new("prometheus_rb_rs", gemspec) do |ext|
  ext.lib_dir = "lib/prometheus_rb_rs"
  ext.cross_compile = true
  ext.cross_platform = platforms
  ext.cross_compiling do |spec|
    spec.dependencies.reject! { |dep| dep.name == "rb_sys" }
    spec.files.reject! { |file| File.fnmatch?("ext/*", file, File::FNM_EXTGLOB) }
  end
end

task :remove_ext do
  path = "lib/prometheus_rb_rs/prometheus_rb_rs.bundle"
  File.unlink(path) if File.exist?(path)
end

Rake::Task["build"].enhance [:remove_ext]

task default: %i[compile spec standard]
