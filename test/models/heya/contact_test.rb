# frozen_string_literal: true

require "test_helper"

module Heya
  class ContactTest < ActiveSupport::TestCase
    test "it keeps campaign memberships on destroy" do
      contact = contacts(:one)
      CampaignMembership.create(user: contact, campaign_gid: "foo")
      memberships = CampaignMembership.where(user_type: "Contact", user_id: contact.id)

      contact.destroy

      assert memberships.any?
    end

    test "it keeps campaign receipts on destroy" do
      contact = contacts(:one)
      CampaignReceipt.create(user: contact, step_gid: "foo")
      receipts = CampaignReceipt.where(user_type: "Contact", user_id: contact.id)

      contact.destroy

      assert receipts.any?
    end
  end
end
