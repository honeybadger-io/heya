module Heya
  module Concerns
    module Models
      module Contact
        extend ActiveSupport::Concern

        included do
          class_attribute :__heya_default_segment, instance_writer: true, instance_predicate: false, default: nil
        end

        module ClassMethods
          # Segments are just scopes, added via the ::segment method (currently
          # just an alias, but I may store these in the future in order to
          # track membership).
          def segment(name, scope_lambda)
            scope(name, scope_lambda)
          end

          def default_segment(&block)
            self.__heya_default_segment = block
          end

          def build_default_segment(relation = relation()) # rubocop:disable Style/MethodCallWithoutArgsParentheses
            __heya_default_segment && relation.instance_exec(&__heya_default_segment) || relation
          end
        end
      end
    end
  end
end
