# frozen_string_literal: true

module InfluxReporter
  # @api private
  class SqlSummarizer
    CACHE = {}.freeze
    TBL = '[^ ]+'
    REGEXES = {
        /^SELECT .* FROM (#{TBL})/i => 'SELECT FROM ',
        /^INSERT INTO (#{TBL})/i => 'INSERT INTO ',
        /^UPDATE (#{TBL})/i => 'UPDATE ',
        /^DELETE FROM (#{TBL})/i => 'DELETE FROM '
    }.freeze

    def initialize(config)
      @config = config
    end

    def signature_for(sql)
      return CACHE[sql] if CACHE[sql]

      result = REGEXES.find do |regex, sig|
        if match = sql.match(regex)
          break sig + match[1]
        end
      end

      result || 'SQL'
    end
  end
end
