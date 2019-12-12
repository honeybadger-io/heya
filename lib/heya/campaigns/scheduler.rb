module Heya
  module Campaigns
    # {Campaigns::Scheduler} schedules campaign jobs to run for each campaign.
    #
    # For each message in each campaign:
    #   1. Find contacts who haven't received message, and are outside
    #      the `wait` window
    #   2. Match segment
    #   3. Create MessageReceipt (excludes contact in subsequent messages)
    #   4. Process job
    class Scheduler
      def run
        # Creates database records if necessary
        Campaigns::Base.subclasses.each(&:load_model)

        Campaign.find_each do |campaign|
          campaign.ordered_messages.each do |message|
            Queries::ContactsForMessage.call(campaign, message).find_each do |contact|
              process(contact, message)
            end
          end

          if (last_message = campaign.ordered_messages.last)
            CampaignMembership.where(
              campaign: campaign,
              contact: Queries::ContactsReceivedMessage.call(campaign, last_message)
            ).destroy_all
          end
        end
      end

      private

      def process(contact, message)
        ActiveRecord::Base.transaction do
          if contact.class.merge(message.build_segment).where(id: contact.id).exists?
            now = Time.now.utc
            CampaignMembership.where(contact: contact).update_all(last_sent_at: now)
            MessageReceipt.create!(message: message, contact: contact, sent_at: now)
            message.action.call(contact: contact, message: message)
          else
            MessageReceipt.create!(message: message, contact: contact)
          end
        end
      end
    end
  end
end
