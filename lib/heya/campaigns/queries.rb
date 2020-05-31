# frozen_string_literal: true

module Heya
  module Campaigns
    module Queries
      MEMBERSHIP_QUERY = <<~SQL
        WITH
          steps AS (SELECT * FROM (VALUES :steps_values) AS steps (gid,wait))
        SELECT
          "memberships".*
        FROM
          "heya_campaign_memberships" AS "memberships"
          INNER JOIN
            "steps" ON "steps".gid = "memberships".step_gid
        WHERE ("memberships".last_sent_at <= (TIMESTAMP :now - make_interval(secs := "steps".wait)))
        AND (
          (:user_type IS NULL OR :user_id IS NULL)
          OR (
            "memberships".user_type = :user_type
            AND
            "memberships".user_id = :user_id
          )
        )
        AND (
          ("memberships".concurrent = TRUE)
          OR "memberships"."campaign_gid" IN (
            SELECT
              "active_membership"."campaign_gid"
            FROM
              "heya_campaign_memberships" as "active_membership"
            WHERE
              "active_membership"."concurrent" = FALSE
              AND
              (
                "active_membership".user_type = "memberships".user_type
                AND
                "active_membership".user_id = "memberships".user_id
              )
            ORDER BY
              array_position(ARRAY[:priority_gids], "active_membership".campaign_gid::text) ASC,
              "active_membership".created_at ASC
            LIMIT 1
          )
        )
        ORDER BY
          "memberships"."created_at" ASC
        LIMIT :limit
        OFFSET :offset
      SQL

      # {Queries::MembershipsToProcess} returns the CampaignMembership records
      # which should be processed by the scheduler.
      MembershipsToProcess = ->(user: nil, &block) {
        now = Time.now.utc

        # https://www.postgresql.org/docs/9.4/queries-values.html
        steps_values = Heya
          .campaigns.reduce([]) { |steps, campaign| steps | campaign.steps }
          .map { |step|
            ActiveRecord::Base.sanitize_sql_array(
              ["(?, ?)", step.gid, step.wait.to_i]
            )
          }.join(", ")

        priority_gids = Heya.config.campaigns.priority.map { |c| (c.is_a?(String) ? c.constantize : c).gid }

        offset = 0
        limit = 1000

        prepared_query = MEMBERSHIP_QUERY.gsub(":steps_values", steps_values)
        loop do
          memberships = CampaignMembership.find_by_sql(
            ActiveRecord::Base.sanitize_sql_array(
              [prepared_query, {
                now: now,
                priority_gids: priority_gids,
                limit: limit,
                offset: offset,
                user_type: user&.class&.base_class&.name,
                user_id: user&.id
              }]
            )
          )
          memberships.each { |membership| block.call(membership) }
          break if memberships.size < limit
          offset += limit
        end
      }

      # Given a campaign and a user, {Queries::MembershipsForUpdate}
      # returns the user's campaign memberships which should be updated
      # concurrently.
      MembershipsForUpdate = ->(campaign, user) {
        membership = CampaignMembership.where(user: user, campaign_gid: campaign.gid).first
        if membership.concurrent?
          CampaignMembership
            .where(user: user, campaign_gid: campaign.gid)
        else
          CampaignMembership
            .where(user: user, concurrent: false)
        end
      }

      # Given a campaign, {Queries::OrphanedStepMemberships} returns the campaign
      # memberships which are on steps have been removed from the campaign.
      OrphanedStepMemberships = ->(campaign) {
        CampaignMembership
          .where(campaign_gid: campaign.gid)
          .where.not(step_gid: campaign.steps.map(&:gid))
      }
    end
  end
end
