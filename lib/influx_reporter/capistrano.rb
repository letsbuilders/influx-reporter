require 'capistrano'
require 'capistrano/version'

if Capistrano::VERSION.to_i <= 2
  require 'influx_reporter/integration/capistrano2'
else
  require 'influx_reporter/integration/capistrano3'
end
