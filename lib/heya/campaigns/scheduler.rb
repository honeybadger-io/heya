module Heya
  module Campaigns
    # {Campaigns::Scheduler} schedules campaign jobs to run for each campaign.
    #
    # For each step in each campaign:
    #   1. Find contacts who haven't completed step, and are outside the `wait`
    #   window
    #   2. Match segment
    #   3. Create CampaignReceipt (excludes contact in subsequent steps)
    #   4. Process job
    class Scheduler
      def run
        Heya.campaigns.each do |campaign|
          campaign.steps.each do |step|
            Queries::ContactsForStep.call(campaign, step).find_each do |contact|
              process(contact, campaign, step)
            end
          end

          if (last_step = campaign.steps.last)
            CampaignMembership.where(
              contact: Queries::ContactsCompletedStep.call(campaign, last_step),
              campaign_gid: campaign.gid,
            ).destroy_all
          end
        end
      end

      private

      def process(contact, campaign, step)
        ActiveRecord::Base.transaction do
          return if CampaignReceipt.where(contact: contact, step_gid: step.gid).exists?

          if contact.class.merge(Queries::SegmentForStep.call(campaign, step)).where(id: contact.id).exists?
            now = Time.now.utc
            CampaignMembership.where(contact: contact, campaign_gid: campaign.gid).update_all(last_sent_at: now)
            CampaignReceipt.create!(contact: contact, step_gid: step.gid, sent_at: now)
            step.action.call(contact: contact, step: step)
          else
            CampaignReceipt.create!(contact: contact, step_gid: step.gid)
          end
        end
      end
    end
  end
end
