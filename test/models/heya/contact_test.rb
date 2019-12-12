require "test_helper"

module Heya
  class ContactTest < ActiveSupport::TestCase
    test "it destroys campaign memberships on destroy" do
      contact = contacts(:one)
      memberships = CampaignMembership.where(contact_id: contact.id)

      FirstCampaign.add(contact)

      assert memberships.any?

      contact.destroy

      refute memberships.any?
    end
  end
end
