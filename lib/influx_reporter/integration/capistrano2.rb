# frozen_string_literal: true

module InfluxReporter
  # @api private
  module Capistrano
    def self.load_into(configuration)
      configuration.load do
        after 'deploy',            'influx_reporter:notify'
        after 'deploy:migrations', 'influx_reporter:notify'
        after 'deploy:cold',       'influx_reporter:notify'
        namespace :influx_reporter do
          desc 'Notifies Opbeat of new deployments'
          task :notify, except: { no_release: true } do
            scm = fetch(:scm)
            if scm.to_s != 'git'
              puts 'Skipping Opbeat deployment notification because scm is not git.'
              next
            end

            branches = capture("cd #{current_release}; /usr/bin/env git branch --contains #{current_revision}").split
            branch = if branches.length == 1
                       branch[0].sub('* ')
                     else
                       nil
                     end

            notify_command = "cd #{current_release}; REV=#{current_revision} "
            notify_command << "BRANCH=#{branch} " if branch

            rails_env = fetch(:rails_env, 'production')
            notify_command << "RAILS_ENV=#{rails_env} "

            executable = fetch(:rake, 'bundle exec rake ')
            notify_command << "#{executable} influx_reporter:release"
            capture notify_command, once: true
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  InfluxReporter::Capistrano.load_into(Capistrano::Configuration.instance)
end
