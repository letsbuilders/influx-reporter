# frozen_string_literal: true

require 'influx_reporter/sql_summarizer'

module InfluxReporter
  module Normalizers
    module ActiveRecord
      class SQL < Normalizer
        register 'sql.active_record'

        def initialize(*args)
          super(*args)
          adapter = begin
                      ::ActiveRecord::Base.connection.adapter_name.downcase
                    rescue
                      nil
                    end
          @kind = "db.#{adapter || 'unknown'}.sql"
          @sql_parser = SqlSummarizer.new config
        end

        def normalize(_transaction, _name, payload)
          return :skip if %w[SCHEMA CACHE].include? payload[:name]

          signature =
            signature_for(payload[:sql]) || # SELECT FROM "users"
            payload[:name] ||               # Users load
            'SQL'

          return :skip if signature == 'SELECT FROM "schema_migrations"'

          [signature, @kind, { sql: payload[:sql] }]
        end

        private

        def signature_for(sql)
          @sql_parser.signature_for(sql)
        end
      end
    end
  end
end
