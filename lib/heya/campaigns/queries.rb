# frozen_string_literal: true

module Heya
  module Campaigns
    module Queries
      NEXT_MESSAGE_SUBQUERY = <<~SQL
        (WITH messages AS (SELECT * FROM (VALUES :messages_values) AS m (message_gid,campaign_gid,position))
         SELECT m.message_gid FROM messages AS m
         WHERE m.campaign_gid = :campaign_gid
           AND m.position > coalesce((SELECT m.position FROM heya_campaign_receipts AS r
             INNER JOIN messages AS m ON m.message_gid = r.message_gid
               AND m.campaign_gid = :campaign_gid
             WHERE r.contact_type = heya_campaign_memberships.contact_type
               AND r.contact_id = heya_campaign_memberships.contact_id
             ORDER BY m.position DESC
             LIMIT 1), -1)
         ORDER BY m.position ASC
         LIMIT 1
        ) = :message_gid
      SQL

      # Given a campaign and a message, {Queries::ContactsForMessage} returns
      # the contacts who should receive the message.
      ContactsForMessage = ->(campaign, message) {
        wait_threshold = Time.now.utc - message.wait

        # Safeguard to make sure we never send the same message twice.
        receipt_query = CampaignReceipt
          .select("heya_campaign_receipts.contact_id")
          .where(contact_type: campaign.contact_class.name)
          .where("heya_campaign_receipts.message_gid = ?", message.gid)

        # https://www.postgresql.org/docs/9.4/queries-values.html
        messages_values = campaign.messages.map { |m|
          ActiveRecord::Base.sanitize_sql_array(
            ["(?, ?, ?)", m.gid, campaign.gid, m.position]
          )
        }.join(", ")

        campaign.contacts
          .where.not(id: receipt_query)
          .where(NEXT_MESSAGE_SUBQUERY.gsub(":messages_values", messages_values), {
            campaign_gid: campaign.gid,
            message_gid: message.gid,
          })
          .where(
            "heya_campaign_memberships.last_sent_at <= ?", wait_threshold
          )
      }

      # Given a campaign and a message, {Queries::ContactsReceivedMessage}
      # returns the contacts who have already received the message.
      ContactsReceivedMessage = ->(campaign, message) {
        receipt_query = CampaignReceipt
          .select("heya_campaign_receipts.contact_id")
          .where(contact_type: campaign.contact_class.name)
          .where("heya_campaign_receipts.message_gid = ?", message.gid)

        campaign.contacts
          .where(id: receipt_query)
      }

      # Given a campaign and a message, {Queries::SegmentForMessage}
      # returns the contacts who should receive the message.
      SegmentForMessage = ->(campaign, message) {
        campaign.contacts
          .build_default_segment
          .instance_exec(&campaign.segment)
          .instance_exec(&message.segment)
      }
    end
  end
end
