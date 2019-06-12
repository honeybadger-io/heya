require "test_helper"

module Heya
  class CampaignTest < ActiveSupport::TestCase
    test "#add adds a contact to a campaign" do
      contact = Contact.create(email: "test@example.com")
      campaign = heya_campaigns(:one)

      campaign.add(contact)

      assert campaign.contacts.where(id: contact).exists?
    end

    test "#remove removes a contact to a campaign" do
      contact = heya_contacts(:one)
      campaign = heya_campaigns(:one)

      assert campaign.contacts.where(id: contact).exists?

      campaign.remove(contact)

      refute campaign.contacts.where(id: contact).exists?
    end
  end
end
