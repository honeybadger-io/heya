require "test_helper"

module Heya
  class CampaignMailerTest < ActionMailer::TestCase
    test "it delivers campaign emails with defaults" do
      contact = contacts(:one)
      step = FirstCampaign.steps.first
      email = CampaignMailer.with(user: contact, step: step).build

      assert_emails 1 do
        email.deliver_now
      end

      assert_equal ["user@example.com"], email.from
    end
  end
end
