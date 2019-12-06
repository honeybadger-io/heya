module Heya
  module Campaigns
    module Queries
      # Given a campaign and a message, {Queries::MessageContactsQuery} returns
      # the contacts who should receive the message.
      MessageContactsQuery = ->(campaign, message) {
        wait_threshold = Time.now.utc - message.wait

        # Send to contacts who have never received this email or any email
        # after it.
        messages = campaign.ordered_messages[campaign.ordered_messages.index(message)..-1]

        receipt_query = MessageReceipt
          .select("heya_message_receipts.contact_id")
          .where(contact_type: message.contact_class.name)
          .where("heya_message_receipts.message_id in (?)", messages.map(&:id))

        campaign.contacts(message.contact_class.name)
          .where.not(id: receipt_query)
          .where(
            "heya_campaign_memberships.last_sent_at <= ?", wait_threshold
          )
          .merge(message.build_segment)
      }
    end
  end
end
