module Heya
  class CampaignReceipt < ApplicationRecord
    belongs_to :contact, polymorphic: true
  end
end
