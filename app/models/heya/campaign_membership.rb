module Heya
  class CampaignMembership < ApplicationRecord
    belongs_to :contact
    belongs_to :campaign

    before_create do
      self.last_sent_at = Time.now
    end
  end
end
