require "test_helper"

module Heya
  class CampaignTest < ActiveSupport::TestCase
    test "#add adds a contact to a campaign" do
      contact = Contact.create(email: "test@example.com")
      campaign = heya_campaigns(:one)

      campaign.add(contact)

      assert campaign.memberships.where(contact: contact).exists?
    end

    test "#remove removes a contact from a campaign" do
      contact = contacts(:one)
      campaign = heya_campaigns(:one)

      assert campaign.memberships.where(contact: contact).exists?

      campaign.remove(contact)

      refute campaign.memberships.where(contact: contact).exists?
    end
  end
end
