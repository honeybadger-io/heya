# frozen_string_literal: true

require "test_helper"

module Heya
  module Campaigns
    class ActionTest < ActiveSupport::TestCase
      include ActiveJob::TestHelper

      test "it queues a default job for step" do
        contact = contacts(:one)
        step = FirstCampaign.steps.first

        assert_enqueued_with(job: StepActionJob, queue: "heya") do
          TestAction.new(user: contact, step: step).deliver_later
        end
      end

      test "it overrides queue from step" do
        contact = contacts(:one)
        step = FirstCampaign.steps.first

        step.stub(:queue, "expected") do
          assert_enqueued_with(job: StepActionJob, queue: "expected") do
            TestAction.new(user: contact, step: step).deliver_later
          end
        end
      end

      test "it raises NotImplementedError for #build" do
        contact = contacts(:one)
        step = FirstCampaign.steps.first

        assert_raise(NotImplementedError) do
          Action.new(user: contact, step: step).build
        end
      end

      test "it calls #deliver on return value of #build" do
        user = contacts(:one)
        step = FirstCampaign.steps.first
        mock = Minitest::Mock.new

        mock.expect(:deliver, nil, [])

        TestAction::Message.stub(:new, mock) do
          TestAction.new(user: user, step: step).deliver_now
        end

        assert_mock mock
      end
    end
  end
end
