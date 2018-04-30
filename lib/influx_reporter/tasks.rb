# frozen_string_literal: true

namespace :influx_reporter do
  desc 'Notify InfluxReporter of a release'
  task release: :environment do
    unless rev = ENV['REV']
      puts "Please specify a revision in an env variable\n" \
           'eg. REV=abc123 rake influx_reporter:release'
      exit 1
    end

    # empty env means dev
    ENV['RAILS_ENV'] ||= 'development'

    # log to STDOUT
    InfluxReporter::Client.inst.config.logger = Logger.new STDOUT

    unless InfluxReporter.release({
                                      rev: rev,
                                      branch: ENV['BRANCH'],
                                      status: 'completed'
                                  }, inline: true)
      exit 1 # release returned nil
    end
  end

  task deployment: :release
end
