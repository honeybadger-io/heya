require "test_helper"

module Heya
  class ContactTest < ActiveSupport::TestCase
    test "it destroys campaign memberships on destroy" do
      contact = contacts(:one)
      CampaignMembership.create(contact: contact, campaign_gid: "foo")
      memberships = CampaignMembership.where(contact_id: contact.id)

      assert memberships.any?

      contact.destroy

      refute memberships.any?
    end

    test "it destroys message receipts on destroy" do
      contact = contacts(:one)
      MessageReceipt.create(contact: contact, message_gid: "foo")
      receipts = MessageReceipt.where(contact_id: contact.id)

      assert receipts.any?

      contact.destroy

      refute receipts.any?
    end
  end
end
