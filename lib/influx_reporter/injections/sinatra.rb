# frozen_string_literal: true

module InfluxReporter
  module Injections
    module Sinatra
      class Injector
        def install
          ::Sinatra::Base.class_eval do
            alias_method :dispatch_without_opb!, :dispatch!
            alias_method :compile_template_with_opb, :compile_template

            def dispatch!(*args, &block)
              dispatch_without_opb!(*args, &block).tap do
                transaction = InfluxReporter.transaction(nil)
                if (route = env['sinatra.route']) && transaction
                  transaction.endpoint = route
                end
              end
            end

            def compile_template(engine, data, opts, *args, &block)
              opts[:__influx_reporter_template_sig] = case data
                                                        when Symbol
                                                          data.to_s
                                                        else
                                                          "Inline #{engine}"
                                                      end

              compile_template_with_opb(engine, data, opts, *args, &block)
            end
          end
        end
      end
    end

    module Tilt
      class Injector
        KIND = 'template.view'

        def install
          ::Tilt::Template.class_eval do
            alias_method :render_without_opb, :render

            def render(*args, &block)
              sig = options[:__influx_reporter_template_sig] || 'Unknown template'

              InfluxReporter.trace sig, KIND do
                render_without_opb(*args, &block)
              end
            end
          end
        end
      end
    end

    register 'Sinatra::Base', 'sinatra/base', Sinatra::Injector.new
    register 'Tilt::Template', 'tilt/template', Tilt::Injector.new
  end
end
