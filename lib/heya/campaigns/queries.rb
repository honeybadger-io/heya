module Heya
  module Campaigns
    module Queries
      # FIXME: Polymorphic types and table names
      NEXT_MESSAGE_SUBQUERY = (<<-SQL).freeze
(SELECT m.id FROM heya_messages AS m
  WHERE m.campaign_id = :campaign_id
  AND m.position > coalesce((SELECT m.position FROM heya_message_receipts AS r
    INNER JOIN heya_messages AS m ON m.id = r.message_id AND m.campaign_id = :campaign_id
    WHERE r.contact_type = 'Contact' AND r.contact_id = contacts.id
    ORDER BY m.position DESC
    LIMIT 1), -1)
  ORDER BY m.position ASC
  LIMIT 1
) = :message_id
SQL

      # Given a campaign and a message, {Queries::ContactsForMessage} returns
      # the contacts who should receive the message.
      ContactsForMessage = ->(campaign, message) {
        wait_threshold = Time.now.utc - message.wait

        # Safeguard to make sure we never send the same message twice.
        receipt_query = MessageReceipt
          .select("heya_message_receipts.contact_id")
          .where(contact_type: message.contact_class.name)
          .where("heya_message_receipts.message_id = ?", message.id)

        campaign.contacts(message.contact_class.name)
          .where.not(id: receipt_query)
          .where(NEXT_MESSAGE_SUBQUERY, {
            campaign_id: campaign.id,
            message_id: message.id
          })
          .where(
            "heya_campaign_memberships.last_sent_at <= ?", wait_threshold
          )
      }

      # Given a campaign and a message, {Queries::ContactsReceivedMessage}
      # returns the contacts who have already received the message.
      ContactsReceivedMessage = ->(campaign, message) {
        receipt_query = MessageReceipt
          .select("heya_message_receipts.contact_id")
          .where(contact_type: message.contact_class.name)
          .where("heya_message_receipts.message_id = ?", message.id)

        campaign.contacts(message.contact_class.name)
          .where(id: receipt_query)
      }
    end
  end
end
