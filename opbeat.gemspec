# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$:.unshift(lib) unless $:.include?(lib)
require 'opbeat/version'

Gem::Specification.new do |gem|
  gem.name             = "influx_reporter"
  gem.version          = InfluxReporter::VERSION
  gem.authors          = ["Kacper Kawecki"]
  gem.email            = "kacper@geniebelt.com"
  gem.summary          = "Metrics collector for rails and Influxdb based on Opbeat Ruby client library"
  gem.homepage         = "https://github.com/GenieBelt/influx-reporter"
  gem.license          = "BSD-3-Clause"

  gem.files            = `git ls-files -z`.split("\x0")
  gem.require_paths    = ["lib"]
  gem.extra_rdoc_files = ["README.md", "LICENSE"]

  gem.add_dependency('activesupport', '>= 3.0.0')
end
