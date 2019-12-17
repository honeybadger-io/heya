module Heya
  class CampaignReceipt < ApplicationRecord
    belongs_to :user, polymorphic: true
  end
end
