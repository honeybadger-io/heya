# frozen_string_literal: true

module Heya
  module Campaigns
    # {Campaigns::Scheduler} schedules campaign jobs to run for each campaign.
    #
    # For each step in each campaign:
    #   1. Find users who haven't completed step, and are outside the `wait`
    #   window
    #   2. Match segment
    #   3. Create CampaignReceipt (excludes user in subsequent steps)
    #   4. Process job
    class Scheduler
      def run
        Heya.campaigns.each do |campaign|
          Queries::OrphanedCampaignMemberships.call(campaign).delete_all

          campaign.steps.each do |step|
            Queries::UsersForStep.call(campaign, step).find_each do |user|
              self.class.process(campaign, step, user)
            end
          end

          if (last_step = campaign.steps.last)
            CampaignMembership.where(
              user: Queries::UsersCompletedStep.call(campaign, last_step),
              campaign_gid: campaign.gid,
            ).delete_all
          end
        end
      end

      def self.process(campaign, step, user)
        ActiveRecord::Base.transaction do
          return if CampaignReceipt.where(user: user, step_gid: step.gid).exists?

          if step.in_segment?(user)
            now = Time.now.utc
            Queries::CampaignMembershipsForUpdate.call(campaign, user).update_all(last_sent_at: now)
            CampaignReceipt.create!(user: user, step_gid: step.gid, sent_at: now)
            step.action.new(user: user, step: step).deliver_later
          else
            CampaignReceipt.create!(user: user, step_gid: step.gid)
          end
        end
      end
    end
  end
end
