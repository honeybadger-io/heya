# frozen_string_literal: true

module Heya
  class CampaignMembership < ApplicationRecord
    belongs_to :user, polymorphic: true

    before_create do
      self.last_sent_at ||= Time.now
    end

    scope :with_steps, -> {
      joins(
        %(INNER JOIN "heya_steps" ON "heya_steps".gid = "heya_campaign_memberships".step_gid)
      )
    }

    scope :active, -> {
      priority_gids = Heya.config.campaigns.priority.map { |c| (c.is_a?(String) ? c.constantize : c).gid }
      where(<<~SQL, priority_gids: priority_gids)
        "heya_campaign_memberships".concurrent = TRUE
        OR "heya_campaign_memberships"."campaign_gid" IN (
          SELECT
            "active_membership"."campaign_gid"
          FROM
            "heya_campaign_memberships" as "active_membership"
          WHERE
            "active_membership"."concurrent" = FALSE
            AND
            (
              "active_membership".user_type = "heya_campaign_memberships".user_type
              AND
              "active_membership".user_id = "heya_campaign_memberships".user_id
            )
          ORDER BY
            array_position(ARRAY[:priority_gids], "active_membership".campaign_gid::text) ASC,
            "active_membership".created_at ASC
          LIMIT 1
        )
      SQL
    }

    scope :upcoming, -> {
      with_steps
        .active
        .order(
          Arel.sql(
            %("heya_campaign_memberships".last_sent_at + make_interval(secs := "heya_steps".wait) DESC)
          )
        )
    }

    scope :to_process, ->(now: Time.now, user: nil) {
      upcoming
        .where(<<~SQL, now: now.utc, user_type: user&.class&.base_class&.name, user_id: user&.id)
          ("heya_campaign_memberships".last_sent_at <= (:now::timestamp - make_interval(secs := "heya_steps".wait)))
          AND (
            (:user_type::text IS NULL OR :user_id::int IS NULL)
            OR (
              "heya_campaign_memberships".user_type = :user_type
              AND
              "heya_campaign_memberships".user_id = :user_id
            )
          )
        SQL
    }

    def self.migrate_next_step!
      find_each do |membership|
        campaign = GlobalID::Locator.locate(membership.campaign_gid)
        receipt = campaign && CampaignReceipt.where(user: membership.user, step_gid: campaign.steps.map(&:gid)).order("created_at desc").first

        next_step = if receipt
          last_step = GlobalID::Locator.locate(receipt.step_gid)
          current_index = campaign.steps.index(last_step)
          campaign.steps[current_index + 1]
        else
          campaign&.steps&.first
        end

        if next_step
          membership.update(step_gid: next_step.gid)
        else
          membership.destroy
        end
      end

      CampaignReceipt.where(sent_at: nil).destroy_all
    end
  end
end
