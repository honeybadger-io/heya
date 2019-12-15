module Heya
  module Campaigns
    # {Campaigns::Scheduler} schedules campaign jobs to run for each campaign.
    #
    # For each message in each campaign:
    #   1. Find contacts who haven't received message, and are outside
    #      the `wait` window
    #   2. Match segment
    #   3. Create CampaignReceipt (excludes contact in subsequent messages)
    #   4. Process job
    class Scheduler
      def run
        Heya.campaigns.each do |campaign|
          campaign.messages.each do |message|
            Queries::ContactsForMessage.call(campaign, message).find_each do |contact|
              process(contact, campaign, message)
            end
          end

          if (last_message = campaign.messages.last)
            CampaignMembership.where(
              contact: Queries::ContactsReceivedMessage.call(campaign, last_message),
              campaign_gid: campaign.gid,
            ).destroy_all
          end
        end
      end

      private

      def process(contact, campaign, message)
        ActiveRecord::Base.transaction do
          return if CampaignReceipt.where(contact: contact, message_gid: message.gid).exists?

          if contact.class.merge(Queries::SegmentForMessage.call(campaign, message)).where(id: contact.id).exists?
            now = Time.now.utc
            CampaignMembership.where(contact: contact, campaign_gid: campaign.gid).update_all(last_sent_at: now)
            CampaignReceipt.create!(contact: contact, message_gid: message.gid, sent_at: now)
            message.action.call(contact: contact, message: message)
          else
            CampaignReceipt.create!(contact: contact, message_gid: message.gid)
          end
        end
      end
    end
  end
end
