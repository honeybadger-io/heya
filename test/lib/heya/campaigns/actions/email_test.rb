# frozen_string_literal: true

require "test_helper"

module Heya
  module Campaigns
    module Actions
      class EmailTest < ActiveSupport::TestCase
        include ActionMailer::TestHelper

        test "it sends an email to user" do
          contact = contacts(:one)
          step = create_test_step(action: Email, subject: "expected subject")
          email = Email.new(user: contact, step: step).build

          assert_emails 1 do
            email.deliver
          end

          assert_equal ["user@example.com"], email.from
          assert_equal [contact.email], email.to
          assert_equal "expected subject", email.subject
        end

        test "to field" do
          contact = contacts(:one)
          step = create_test_step(action: Email, subject: "expected subject")
          email = Email.new(user: contact, step: step).build

          def first_name = "John"

          def name = "John Doe"

          def nickname = "Jhonny Doe"

          assert_emails 1 do
            email.deliver
          end

          assert_equal "John <one@example.com>", email.header[:to].value

          contact.instance_exec { undef :first_name }

          email = Email.new(user: contact, step: step).build

          assert_emails 1 do
            email.deliver
          end

          assert_equal "John Doe <one@example.com>", email.header[:to].value

          contact.instance_exec { undef :name }

          step = create_test_step(
            action: Email,
            subject: "expected subject",
            to: ->(user) { Heya::CampaignMailer.email_address_with_name(user.email, user.nickname) }
          )
          email = Email.new(user: contact, step: step).build

          assert_emails 1 do
            email.deliver
          end

          assert_equal "Jhonny Doe <one@example.com>", email.header[:to].value
        end

        test "it raises an exception without a subject" do
          assert_raise ArgumentError, /subject/ do
            create_test_step(action: Email)
          end
        end

        test "it raises an exception with invalid params" do
          assert_raise ArgumentError, /invalid/ do
            create_test_step(action: Email, subject: "heya", invalid: true)
          end
        end

        test "it doesn't raise exception with locale" do
          I18n.with_locale(:test_campaign_interpolation) do
            assert_kind_of Step, create_test_step(action: Email)
          end
        end
      end
    end
  end
end
