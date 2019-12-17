module Heya
  module Concerns
    module Models
      module User
        extend ActiveSupport::Concern

        included do
          class_attribute :__heya_default_segment, instance_writer: true, instance_predicate: false, default: nil
          has_many :heya_campaign_memberships, class_name: "Heya::CampaignMembership", as: :user, dependent: :destroy
          has_many :heya_campaign_receipts, class_name: "Heya::CampaignReceipt", as: :user, dependent: :destroy
        end

        module ClassMethods
          def default_segment(&block)
            self.__heya_default_segment = block
          end
        end
      end
    end
  end
end
