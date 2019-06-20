module Heya
  module Campaigns
    module Queries
      # Given a campaign and a message, {Queries::MessageContactsQuery} returns
      # the contacts who should receive the message.
      MessageContactsQuery = ->(campaign, message) {
        wait_threshold = Time.now.utc - message.wait

        receipt_query = MessageReceipt
          .select("heya_message_receipts.contact_id")
          .where(contact_type: message.contact_class.name)
          .where("heya_message_receipts.message_id  = ?", message.id)

        campaign.contacts(message.contact_class.name)
          .where.not(id: receipt_query)
          .where(
            "heya_campaign_memberships.last_sent_at <= ?", wait_threshold
          )
          .merge(message.segment)
      }
    end
  end
end
