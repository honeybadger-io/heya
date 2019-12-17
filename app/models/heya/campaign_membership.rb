module Heya
  class CampaignMembership < ApplicationRecord
    belongs_to :user, polymorphic: true

    before_create do
      self.last_sent_at = Time.now
    end
  end
end
