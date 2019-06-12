module Heya
  module Concerns
    module Models
      module Contact
        extend ActiveSupport::Concern

        included do
          self.table_name = "heya_contacts"

          has_many :campaign_memberships
          has_many :campaigns, through: :campaign_memberships

          has_many :message_receipts
        end

        def to_s
          email.to_s
        end

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
