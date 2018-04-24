module InfluxReporter
  class Middleware
    def initialize app
      @app = app
    end

    def call env
      begin
        transaction = InfluxReporter.transaction "Rack", "app.rack.request"
        resp = @app.call env
        resp[2] = BodyProxy.new(resp[2]) { transaction.submit(resp[0]) } if transaction
      rescue Error
        raise # Don't report Opbeat errors
      rescue Exception => e
        InfluxReporter.report e, rack_env: env
        transaction.submit(500) if transaction
        raise
      ensure
        transaction.release if transaction
      end

      if error = env['rack.exception'] || env['sinatra.error']
        InfluxReporter.report error, rack_env: env
      end

      resp
    end
  end

  class BodyProxy
    def initialize body, &block
      @body, @block, @closed = body, block, false
    end

    def respond_to? *args
      super || @body.respond_to?(*args)
    end

    def close
      return if closed?

      @closed = true

      begin
        @body.close if @body.respond_to?(:close)
      ensure
        @block.call
      end
    end

    def closed?
      @closed
    end

    def method_missing *args, &block
      @body.__send__(*args, &block)
    end
  end
end
