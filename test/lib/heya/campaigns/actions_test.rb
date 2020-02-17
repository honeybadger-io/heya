require "test_helper"

module Heya
  module Campaigns
    class ActionsTest < ActiveSupport::TestCase
      include ActionMailer::TestHelper

      test "it sends an email to user" do
        contact = contacts(:one)
        step = FirstCampaign.steps.first

        assert_emails 1 do
          Actions::Email.new(user: contact, step: step).deliver_now
        end
      end

      test "it queues a default job for step" do
        contact = contacts(:one)
        step = FirstCampaign.steps.first

        assert_enqueued_with(job: StepActionJob, queue: "heya") do
          Actions::Email.new(user: contact, step: step).deliver_later
        end
      end

      test "it queues a custom job for step" do
        contact = contacts(:one)
        step = FirstCampaign.steps.first
        step.stub(:queue, "expected") do
          assert_enqueued_with(job: StepActionJob, queue: "expected") do
            Actions::Email.new(user: contact, step: step).deliver_later
          end
        end
      end

      test "block actions can be called with one argument" do
        mock = MiniTest::Mock.new
        block = proc { |u| mock.call(u) }
        step = OpenStruct.new(properties: {block: block})
        action = Actions::Block.new(user: :user, step: step)

        mock.expect(:call, nil, [:user])
        action.deliver_now
        assert_mock mock
      end

      test "block actions can be called with no arguments" do
        mock = MiniTest::Mock.new
        block = proc { mock.call }
        step = OpenStruct.new(properties: {block: block})
        action = Actions::Block.new(user: :user, step: step)

        mock.expect(:call, nil, [])
        action.deliver_now
        assert_mock mock
      end
    end
  end
end
