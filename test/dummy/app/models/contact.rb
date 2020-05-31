class Contact < ApplicationRecord
  has_many :heya_campaign_memberships, class_name: "Heya::CampaignMembership", as: :user, dependent: :delete_all
  has_many :heya_campaign_receipts, class_name: "Heya::CampaignReceipt", as: :user, dependent: :delete_all
  store :traits, coder: JSON

  def heya_attributes
    traits
  end
end
