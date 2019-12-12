require "test_helper"

module Heya
  class ContactTest < ActiveSupport::TestCase
    test "it destroys campaign memberships on destroy" do
      contact = contacts(:one)
      memberships = CampaignMembership.where(contact_id: contact.id)

      assert memberships.any?

      contact.destroy

      refute memberships.any?
    end

    test "it destroys message receipts on destroy" do
      contact = contacts(:one)
      receipts = MessageReceipt.where(contact_id: contact.id)

      assert receipts.any?

      contact.destroy

      refute receipts.any?
    end
  end
end
