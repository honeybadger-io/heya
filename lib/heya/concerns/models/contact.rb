module Heya
  module Concerns
    module Models
      module Contact
        extend ActiveSupport::Concern

        module ClassMethods
          # Segments are just scopes, added via the ::segment method (currently
          # just an alias, but I may store these in the future in order to
          # track membership).
          def segment(name, scope_lambda)
            scope(name, scope_lambda)
          end
        end
      end
    end
  end
end
