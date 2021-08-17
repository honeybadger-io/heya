# frozen_string_literal: true

require "test_helper"

module Heya
  class CampaignMailerTest < ActionMailer::TestCase

    test "it delivers campaign emails with defaults plus bcc at step level" do
      contact = contacts(:one)
      step = create_test_step(
        action: Campaigns::Actions::Email,
        subject: "Expected subject",
        bcc: 'quality_control@example.com'
      )
      email = CampaignMailer.with(user: contact, step: step).build

      assert_emails 1 do
        email.deliver_now
      end

      assert_equal ["user@example.com"], email.from
      assert_equal "Expected subject", email.subject
      assert_equal ["quality_control@example.com"], email.bcc 
    end

    test "it delivers campaign emails with defaults" do
      contact = contacts(:one)
      step = create_test_step(
        action: Campaigns::Actions::Email,
        subject: "Expected subject"
      )
      email = CampaignMailer.with(user: contact, step: step).build

      assert_emails 1 do
        email.deliver_now
      end

      assert_equal ["user@example.com"], email.from
      assert_equal "Expected subject", email.subject
    end

    test "it falls back to i18n for subject" do
      contact = contacts(:one)
      contact.traits["first_name"] = "Hunter"

      I18n.with_locale(:test_campaign_interpolation) do
        step = create_test_step(action: Campaigns::Actions::Email)
        email = CampaignMailer.with(user: contact, step: step).build
        assert_equal "Heya Hunter", email.subject
      end
    end

    test "it calls block for subject" do
      contact = contacts(:one)
      contact.traits["first_name"] = "Hunter"
      step = create_test_step(
        action: Campaigns::Actions::Email,
        subject: ->(u) { "Heya #{u.traits["first_name"]}" }
      )
      email = CampaignMailer.with(user: contact, step: step).build

      assert_equal "Heya Hunter", email.subject
    end
  end
end
