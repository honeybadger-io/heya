require "test_helper"

module Heya
  class ActionsTest < ActiveSupport::TestCase
    include ActionMailer::TestHelper

    test "it sends an email to contact" do
      contact = contacts(:one)
      message = heya_messages(:one)

      assert_enqueued_email_with CampaignMailer, :build, args: {contact: contact, message: message} do
        Actions::Email.call(contact: contact, message: message)
      end
    end
  end
end
