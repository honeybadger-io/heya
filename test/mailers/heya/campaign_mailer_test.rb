# frozen_string_literal: true

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
      assert_equal "First subject", email.subject
    end

    test "it falls back to i18n for subject" do
      contact = contacts(:one)
      step = FirstCampaign.steps.first.dup

      step.params = step.params.dup
      step.params.delete("subject")
      contact.traits["first_name"] = "Hunter"

      I18n.with_locale(:first_campaign_interpolation) do
        email = CampaignMailer.with(user: contact, step: step).build
        assert_equal "Heya Hunter", email.subject
      end
    end

    test "it calls block for subject" do
      contact = contacts(:one)
      step = FirstCampaign.steps.first.dup

      step.params = step.params.dup
      step.params["subject"] = ->(u) { "Heya #{u.traits["first_name"]}" }
      contact.traits["first_name"] = "Hunter"
      email = CampaignMailer.with(user: contact, step: step).build

      assert_equal "Heya Hunter", email.subject
    end
  end
end
