# frozen_string_literal: true

require "test_helper"

module Heya
  class CampaignMembershipTest < ActiveSupport::TestCase
    test "it sets default last_sent_at time" do
      membership = CampaignMembership.create(
        campaign_gid: FirstCampaign.gid,
        step_gid: FirstCampaign.steps.first.gid,
        user: contacts(:new)
      )

      assert membership.last_sent_at.is_a?(Time)
    end

    test ".migrate_next_step! selects first step" do
      membership = CampaignMembership.create(
        campaign_gid: FirstCampaign.gid,
        step_gid: "gid://heya/null",
        user: contacts(:one)
      )

      CampaignMembership.migrate_next_step!

      assert_equal FirstCampaign.steps.first.gid, membership.reload.step_gid
    end

    test ".migrate_next_step! selects next step" do
      membership = CampaignMembership.create(
        campaign_gid: FirstCampaign.gid,
        step_gid: "gid://heya/null",
        user: contacts(:one)
      )
      CampaignReceipt.create(user: contacts(:one), step_gid: FirstCampaign.steps.first.gid, sent_at: Time.now)
      CampaignReceipt.create(user: contacts(:one), step_gid: FirstCampaign.steps.second.gid, sent_at: Time.now)

      assert_no_difference "CampaignReceipt.count" do
        CampaignMembership.migrate_next_step!
      end

      assert_equal FirstCampaign.steps.third.gid, membership.reload.step_gid
    end

    test ".migrate_next_step! removes orphaned memberships" do
      CampaignMembership.create(
        campaign_gid: "gid://heya/null",
        step_gid: "gid://heya/null",
        user: contacts(:one)
      )

      assert_difference "CampaignMembership.count", -1 do
        CampaignMembership.migrate_next_step!
      end
    end

    test ".migrate_next_step! removes unsent receipts" do
      membership = CampaignMembership.create(
        campaign_gid: FirstCampaign.gid,
        step_gid: "gid://heya/null",
        user: contacts(:one)
      )
      CampaignReceipt.create(user: contacts(:one), step_gid: FirstCampaign.steps.first.gid, sent_at: nil)
      CampaignReceipt.create(user: contacts(:one), step_gid: FirstCampaign.steps.second.gid, sent_at: Time.now)

      assert_difference "CampaignReceipt.count", -1 do
        CampaignMembership.migrate_next_step!
      end

      assert_equal FirstCampaign.steps.third.gid, membership.reload.step_gid
    end
  end
end
