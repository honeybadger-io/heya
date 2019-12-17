require "test_helper"

module Heya
  module Models
    module Concerns
      class UserTest < ActiveSupport::TestCase
        include ActionMailer::TestHelper

        class DefaultSegmentContact < Contact
          default_segment { where(email: "one@example.com") }
        end

        test "has a default segment of all" do
          assert_equal [contacts(:one), contacts(:two)], Contact.build_default_segment.limit(2).to_a
        end

        test "can override the default segment via lambda" do
          assert_equal [contacts(:one)], (DefaultSegmentContact.build_default_segment.limit(2).to_a.map { |m| m.becomes(Contact) })
        end
      end
    end
  end
end
