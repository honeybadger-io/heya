module Heya
  class CampaignMembership < ApplicationRecord
    belongs_to :user, polymorphic: true

    before_create do
      self.last_sent_at = Time.now
    end

    def self.migrate_next_step!
      find_each do |membership|
        campaign = GlobalID::Locator.locate(membership.campaign_gid)
        receipt = campaign && CampaignReceipt.where(user: membership.user, step_gid: campaign.steps.map(&:gid)).order("created_at desc").first

        next_step = if receipt
          last_step = GlobalID::Locator.locate(receipt.step_gid)
          current_index = campaign.steps.index(last_step)
          campaign.steps[current_index + 1]
        else
          campaign&.steps&.first
        end

        if next_step
          membership.update(step_gid: next_step.gid)
        else
          membership.destroy
        end
      end

      CampaignReceipt.where(sent_at: nil).destroy_all
    end
  end
end
