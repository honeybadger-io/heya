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

      ACTIVE_CAMPAIGN_SUBQUERY = <<~SQL
        (WITH heya_campaigns AS (SELECT * FROM (VALUES :campaigns_values) AS campaigns (campaign_gid,position))
        SELECT memberships.campaign_gid FROM heya_campaign_memberships AS memberships
         INNER JOIN heya_campaigns AS campaigns
           ON campaigns.campaign_gid = memberships.campaign_gid
         WHERE memberships.user_type = heya_campaign_memberships.user_type
           AND memberships.user_id = heya_campaign_memberships.user_id
           AND memberships.concurrent = FALSE
         ORDER BY campaigns.position DESC, memberships.created_at ASC
         LIMIT 1
        ) = :campaign_gid
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

        priority = Heya.config.campaigns.priority.reverse
        campaigns_values = Heya.campaigns.map { |c|
          ActiveRecord::Base.sanitize_sql_array(
            ["(?, ?)", c.gid, priority.index(c) || -1]
          )
        }.join(", ")

        users = campaign.users
        users
          .where.not(id: receipt_query)
          .where(NEXT_STEP_SUBQUERY.gsub(":steps_values", steps_values), {
            campaign_gid: campaign.gid,
            step_gid: step.gid,
          })
          .merge(
            users
              .where("heya_campaign_memberships.concurrent = ?", true)
              .or(
                users.where(ACTIVE_CAMPAIGN_SUBQUERY.gsub(":campaigns_values", campaigns_values), {
                  campaign_gid: campaign.gid,
                })
              )
          )
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

      # Given a campaign and a user, {Queries::CampaignMembershipsForUpdate}
      # returns the user's campaign memberships which should be updated
      # concurrently.
      CampaignMembershipsForUpdate = ->(campaign, user) {
        membership = CampaignMembership.where(user: user, campaign_gid: campaign.gid).first
        if membership.concurrent?
          CampaignMembership
            .where(user: user, campaign_gid: campaign.gid)
        else
          CampaignMembership
            .where(user: user, concurrent: false)
        end
      }

      # Given a campaign, {Queries::OrphanedCampaignMemberships} returns the
      # campaign memberships which belong to users who no longer exist in the
      # database.
      OrphanedCampaignMemberships = ->(campaign) {
        CampaignMembership
          .where(campaign_gid: campaign.gid)
          .where(user_type: campaign.user_class.base_class.name)
          .where.not(user_id: campaign.users.select("id"))
      }
    end
  end
end
