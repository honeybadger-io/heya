require "test_helper"

module Heya
  class CampaignMembershipTest < ActiveSupport::TestCase
    test "it sets default last_sent_at time" do
      membership = CampaignMembership.create(
        contact: contacts(:new),
        campaign: heya_campaigns(:one)
      )

      assert membership.last_sent_at.is_a?(Time)
    end
  end
end
