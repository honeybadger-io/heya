# frozen_string_literal: true

require "test_helper"

module Heya
  module Campaigns
    class StepActionJobTest < ActiveJob::TestCase
      test "it executes the action" do
        user = contacts(:one)
        step = FirstCampaign.steps.first
        mock = Minitest::Mock.new

        mock.expect(:call, nil, [user, step])

        TestAction.mock(mock) do
          step.stub(:action, TestAction) do
            StepActionJob.perform_now("FirstCampaign", user, step)
          end
        end

        assert_mock mock
      end

      test "it raises errors by default" do
        user = contacts(:one)
        step = FirstCampaign.steps.first
        result = ->(user, step) { raise "expected error" }

        TestAction.mock(result) do
          step.stub(:action, TestAction) do
            assert_raise "expected error" do
              StepActionJob.perform_now("FirstCampaign", user, step)
            end
          end
        end
      end

      test "it handles errors with campaign class" do
        mock = Minitest::Mock.new
        user = contacts(:one)
        step = FirstCampaign.steps.first
        exception = StandardError.new("expected error")
        result = ->(user, step) { raise exception }

        mock.expect(:call, nil, [exception])

        FirstCampaign.stub(:handle_exception, mock) do
          TestAction.mock(result) do
            step.stub(:action, TestAction) do
              StepActionJob.perform_now("FirstCampaign", user, step)
            end
          end
        end

        assert_mock mock
      end
    end
  end
end
