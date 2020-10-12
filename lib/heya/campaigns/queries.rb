# frozen_string_literal: true

module Heya
  module Campaigns
    module Queries
      # {Queries::MembershipsToProcess} returns the CampaignMembership records
      # which should be processed by the scheduler.
      MembershipsToProcess = ->(user: nil) {
        Heya::CampaignMembership.to_process(user: user)
      }

      # Given a campaign and a user, {Queries::MembershipsForUpdate}
      # returns the user's campaign memberships which should be updated
      # concurrently.
      MembershipsForUpdate = ->(campaign, user) {
        membership = CampaignMembership.where(user: user, campaign_gid: campaign.gid).first
        if membership.concurrent?
          CampaignMembership
            .where(user: user, campaign_gid: campaign.gid)
        else
          CampaignMembership
            .where(user: user, concurrent: false)
        end
      }

      # Given a campaign, {Queries::OrphanedMemberships} returns the campaign
      # memberships which are on steps have been removed from the campaign.
      OrphanedMemberships = ->(campaign) {
        CampaignMembership
          .where(campaign_gid: campaign.gid)
          .where.not(step_gid: campaign.steps.map(&:gid))
      }
    end
  end
end
