
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'influx_reporter/version'

Gem::Specification.new do |gem|
  gem.name             = 'influx_reporter'
  gem.version          = InfluxReporter::VERSION
  gem.authors          = ['Kacper Kawecki']
  gem.email            = 'kacper@geniebelt.com'
  gem.summary          = 'Metrics collector for rails and InfluxDB based on Opbeat Ruby client library'
  gem.homepage         = 'https://github.com/GenieBelt/influx-reporter'
  gem.license          = 'BSD-3-Clause'

  gem.files            = `git ls-files -z`.split("\x0")
  gem.require_paths    = ['lib']
  gem.extra_rdoc_files = %w[README.md LICENSE]

  gem.required_ruby_version = '>= 2.3.0'
  gem.add_dependency('activesupport', '>= 3.0.0')
  gem.add_dependency('influxdb', '>= 0.5.3')

  gem.add_development_dependency('rubocop')
end
