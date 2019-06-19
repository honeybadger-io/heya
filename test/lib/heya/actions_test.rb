require "test_helper"

module Heya
  class ActionsTest < ActiveSupport::TestCase
    include ActionMailer::TestHelper

    test "it sends an email to contact" do
      contact = contacts(:one)
      message = heya_messages(:one)
      message.properties = {"subject" => "expected subject"}

      assert_emails 1 do
        email = Actions::Email.call(contact: contact, message: message)

        assert_equal "expected subject", email.subject
        assert_equal "one@example.com", email.to.first
      end
    end
  end
end
