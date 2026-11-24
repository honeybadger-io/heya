# frozen_string_literal: true

require "test_helper"

module Heya
  module Campaigns
    class StepTest < ActiveSupport::TestCase
      test "it checks segment for user" do
        campaign = create_test_campaign {
          step :one, segment: ->(c) { c.traits["name"] != "Jack" }
          user_type "Contact"
        }
        step = campaign.steps.first
        contact = contacts(:one)

        assert step.in_segment?(contact)

        contact.traits["name"] = "Jack"

        refute step.in_segment?(contact)
      end

      test "it is located by Global ID fetch" do
        campaign = create_test_campaign {
          step :one
          step :two
        }
        one, two = campaign.steps

        assert_equal one, GlobalID::Locator.fetch(one.gid)
        assert_equal [two], Step.where(id: [two.id, "#{campaign.name}/missing"])
      end
    end
  end
end
