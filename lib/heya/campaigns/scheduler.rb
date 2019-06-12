module Heya
  module Campaigns
    # Campaigns::Scheduler schedules campaign jobs to run for each campaign.
    #
    # For each message in each campaign:
    #   1. Find contacts who haven't received message, and are outside
    #      the `wait` window
    #   2. Match segment
    #   3. Create MessageReceipt (excludes contact in subsequent messages)
    #   4. Process job
    class Scheduler
      def run
        Campaign.find_each do |campaign|
          campaign.name.constantize.messages.each do |message|
            Queries::MessageContactsQuery.call(campaign, message).find_each do |contact|
              process(contact, message)
            end
          end
        end
      end

      private

      def process(contact, message)
        ActiveRecord::Base.transaction do
          now = Time.now.utc
          CampaignMembership.where(contact: contact).update_all(last_sent_at: now)
          MessageReceipt.create!(message: message, contact: contact, sent_at: now)
          message.properties.fetch(:action).call(contact: contact, message: message)
        end
      end
    end
  end
end
