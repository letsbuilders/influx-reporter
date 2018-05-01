# frozen_string_literal: true

module InfluxReporter
  module Injections
    module NetHTTP
      class Injector
        def install
          Net::HTTP.class_eval do
            alias_method :request_without_opb, :request

            def request(req, body = nil, &block)
              unless InfluxReporter.started?
                return request_without_opb req, body, &block
              end

              host, port = req['host']&.split(':')
              method = req.method
              path = req.path
              scheme = use_ssl? ? 'https' : 'http'

              # inside a session
              host ||= address
              port ||= use_ssl? ? 443 : 80

              extra = {
                  tags: {
                      scheme: scheme,
                      port: port,
                      method: method
                  },
                  values: {
                      path: path
                  }
              }

              signature = host
              kind = 'ext.net_http'

              InfluxReporter.trace signature, kind, extra do
                request_without_opb(req, body, &block)
              end
            end
          end
        end
      end
    end

    register 'Net::HTTP', 'net/http', NetHTTP::Injector.new
  end
end
