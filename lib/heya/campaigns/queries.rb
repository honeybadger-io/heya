module Heya
  module Campaigns
    module Queries
      # Given a campaign and a message, MessageContactsQuery returns the
      # contacts who should receive the message.
      MessageContactsQuery = ->(campaign, message) {
        wait_threshold = Time.now.utc - message.properties.fetch(:wait)
        contact_class = message.properties[:contact_class].constantize
        segment = contact_class.instance_exec(&message.properties.fetch(:segment))

        receipt_query = MessageReceipt
          .select("heya_message_receipts.contact_id")
          .where(contact_type: contact_class.name)
          .where("heya_message_receipts.message_id  = ?", message.id)

        campaign.contacts(contact_class.name)
          .where.not(id: receipt_query)
          .where(
            "heya_campaign_memberships.last_sent_at <= ?", wait_threshold
          )
          .merge(segment)
      }
    end
  end
end
