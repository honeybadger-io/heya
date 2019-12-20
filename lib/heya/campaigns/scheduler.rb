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
          campaign.steps.each do |step|
            Queries::UsersForStep.call(campaign, step).find_each do |user|
              process(user, campaign, step)
            end
          end

          if (last_step = campaign.steps.last)
            CampaignMembership.where(
              user: Queries::UsersCompletedStep.call(campaign, last_step),
              campaign_gid: campaign.gid,
            ).destroy_all
          end
        end
      end

      private

      def process(user, campaign, step)
        ActiveRecord::Base.transaction do
          return if CampaignReceipt.where(user: user, step_gid: step.gid).exists?

          if Heya.in_segments?(user, user.class.__heya_default_segment, campaign.segment, step.segment)
            now = Time.now.utc
            CampaignMembership.where(user: user).merge(CampaignMembership.where(campaign_gid: campaign.gid).or(CampaignMembership.where(concurrent: false))).update_all(last_sent_at: now)
            CampaignReceipt.create!(user: user, step_gid: step.gid, sent_at: now)
            step.action.call(user: user, step: step)
          else
            CampaignReceipt.create!(user: user, step_gid: step.gid)
          end
        end
      end
    end
  end
end
