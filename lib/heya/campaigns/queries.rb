module Heya
  module Campaigns
    module Queries
      # Given a campaign and a message, MessageContactsQuery returns the
      # contacts who should receive the message.
      MessageContactsQuery = ->(campaign, message) {
        wait_threshold = Time.now.utc - message.properties.fetch(:wait)

        receipt_query = MessageReceipt
          .select("heya_message_receipts.contact_id")
          .where("heya_message_receipts.message_id  = ?", message.id)

        select = campaign.contacts.joins(:campaign_memberships)
        select
          .where.not(id: receipt_query)
          .where(
            "heya_campaign_memberships.last_sent_at <= ?", wait_threshold
          )
          .merge(message.properties.fetch(:segment))
      }
    end
  end
end
