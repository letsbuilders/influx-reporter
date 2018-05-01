# frozen_string_literal: true

module InfluxReporter
  module Normalizers
    module ActionView
      class RenderNormalizer < Normalizer
        def normalize_render(payload, kind)
          signature = path_for(payload[:identifier])

          [signature, kind, nil]
        end

        private

        def path_for(identifier)
          return 'Unknown template' unless path = identifier
          return path unless path.start_with?('/')

          path && relative_path(path)
        end

        def relative_path(path)
          root = config.view_paths.find { |vp| path.start_with? vp }
          type = :app

          unless root
            root = Gem.path.find { |gp| path.start_with? gp }
            type = :gem
          end

          return 'Absolute path' unless root

          start = root.length
          start += 1 if path[root.length] == '/'

          if type == :gem
            "$GEM_PATH/#{path[start, path.length]}"
          else
            path[start, path.length]
          end
        end
      end

      class RenderTemplate < RenderNormalizer
        register 'render_template.action_view'
        KIND = 'template.view'

        def normalize(_transaction, _name, payload)
          normalize_render(payload, KIND)
        end
      end

      class RenderPartial < RenderNormalizer
        register 'render_partial.action_view'
        KIND = 'template.view.partial'

        def normalize(_transaction, _name, payload)
          normalize_render(payload, KIND)
        end
      end

      class RenderCollection < RenderNormalizer
        register 'render_collection.action_view'
        KIND = 'template.view.collection'

        def normalize(_transaction, _name, payload)
          normalize_render(payload, KIND)
        end
      end
    end
  end
end
