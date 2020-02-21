# frozen_string_literal: true

require "test_helper"

module Heya
  module Campaigns
    module Actions
      class EmailTest < ActiveSupport::TestCase
        include ActionMailer::TestHelper

        test "it sends an email to user" do
          contact = contacts(:one)
          step = FirstCampaign.steps.first
          email = Email.new(user: contact, step: step).build

          assert_emails 1 do
            email.deliver
          end

          assert_equal ["user@example.com"], email.from
          assert_equal [contact.email], email.to
        end
      end
    end
  end
end
