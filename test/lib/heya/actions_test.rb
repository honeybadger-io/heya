require "test_helper"

module Heya
  class ActionsTest < ActiveSupport::TestCase
    include ActionMailer::TestHelper

    test "it sends an email to contact" do
      contact = contacts(:one)
      step = FirstCampaign.steps.first

      assert_enqueued_email_with CampaignMailer, :build, args: {contact: contact, step: step} do
        Actions::Email.call(contact: contact, step: step)
      end
    end
  end
end
