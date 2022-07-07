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
      def run(user: nil)
        Heya.campaigns.each do |campaign|
          if campaign.steps.any?
            Queries::OrphanedMemberships.call(campaign).update_all(step_gid: campaign.steps.first.gid)
          end
        end

        Queries::MembershipsToProcess.call(user: user).find_each do |membership|
          step = GlobalID::Locator.locate(membership.step_gid)
          campaign = GlobalID::Locator.locate(membership.campaign_gid)

          if membership.user.nil?
            # User not found; delete orphaned memberships and receipts.
            CampaignReceipt.where(
              user_type: membership.user_type,
              user_id: membership.user_id
            ).delete_all
            CampaignMembership.where(
              user_type: membership.user_type,
              user_id: membership.user_id
            ).delete_all
            next
          end

          process(campaign, step, membership.user)

          current_index = campaign.steps.index(step)
          if (next_step = campaign.steps[current_index + 1])
            membership.update(step_gid: next_step.gid)
          else
            membership.destroy
          end
        end
      end

      private

      def process(campaign, step, user)
        ActiveRecord::Base.transaction do
          return if CampaignReceipt.where(user: user, step_gid: step.gid).exists?

          if step.in_segment?(user)
            now = Time.now.utc
            Queries::MembershipsForUpdate.call(campaign, user).update_all(last_sent_at: now)
            CampaignReceipt.create!(user: user, step_gid: step.gid, sent_at: now)
            step.action.new(user: user, step: step).deliver_later
          end
        end
      end
    end
  end
end
