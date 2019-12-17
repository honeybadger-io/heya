# frozen_string_literal: true

module Heya
  module Campaigns
    module Queries
      NEXT_STEP_SUBQUERY = <<~SQL
        (WITH steps AS (SELECT * FROM (VALUES :steps_values) AS m (step_gid,campaign_gid,position))
         SELECT m.step_gid FROM steps AS m
         WHERE m.campaign_gid = :campaign_gid
           AND m.position > coalesce((SELECT m.position FROM heya_campaign_receipts AS r
             INNER JOIN steps AS m ON m.step_gid = r.step_gid
               AND m.campaign_gid = :campaign_gid
             WHERE r.user_type = heya_campaign_memberships.user_type
               AND r.user_id = heya_campaign_memberships.user_id
             ORDER BY m.position DESC
             LIMIT 1), -1)
         ORDER BY m.position ASC
         LIMIT 1
        ) = :step_gid
      SQL

      # Given a campaign and a step, {Queries::UsersForStep} returns the
      # users who should complete the step.
      UsersForStep = ->(campaign, step) {
        wait_threshold = Time.now.utc - step.wait

        # Safeguard to make sure we never complete the same step twice.
        receipt_query = CampaignReceipt
          .select("heya_campaign_receipts.user_id")
          .where(user_type: campaign.user_class.name)
          .where("heya_campaign_receipts.step_gid = ?", step.gid)

        # https://www.postgresql.org/docs/9.4/queries-values.html
        steps_values = campaign.steps.map { |m|
          ActiveRecord::Base.sanitize_sql_array(
            ["(?, ?, ?)", m.gid, campaign.gid, m.position]
          )
        }.join(", ")

        campaign.users
          .where.not(id: receipt_query)
          .where(NEXT_STEP_SUBQUERY.gsub(":steps_values", steps_values), {
            campaign_gid: campaign.gid,
            step_gid: step.gid,
          })
          .where(
            "heya_campaign_memberships.last_sent_at <= ?", wait_threshold
          )
      }

      # Given a campaign and a step, {Queries::UsersCompletedStep}
      # returns the users who have completed the step.
      UsersCompletedStep = ->(campaign, step) {
        receipt_query = CampaignReceipt
          .select("heya_campaign_receipts.user_id")
          .where(user_type: campaign.user_class.name)
          .where("heya_campaign_receipts.step_gid = ?", step.gid)

        campaign.users
          .where(id: receipt_query)
      }
    end
  end
end
