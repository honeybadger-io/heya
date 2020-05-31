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
  end
end
