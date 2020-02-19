module Heya
  module Concerns
    module Models
      module User
        extend ActiveSupport::Concern

        included do
          has_many :heya_campaign_memberships, class_name: "Heya::CampaignMembership", as: :user, dependent: :destroy
          has_many :heya_campaign_receipts, class_name: "Heya::CampaignReceipt", as: :user, dependent: :destroy
        end
      end
    end
  end
end
