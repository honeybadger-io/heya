require "test_helper"

module Heya
  module Campaigns
    class ActionsTest < ActiveSupport::TestCase
      include ActionMailer::TestHelper

      test "it sends an email to user" do
        contact = contacts(:one)
        step = FirstCampaign.steps.first

        assert_enqueued_email_with CampaignMailer, :build, args: {user: contact, step: step} do
          Actions::Email.call(user: contact, step: step).deliver_later
        end
      end

      test "block actions respond to ActionMailer::MessageDelivery API subset" do
        mock = MiniTest::Mock.new
        block = Proc.new { |user, step|
          mock.call(user, step)
        }
        action = Actions::Block.build(block)

        mock.expect(:call, nil, [:user, :step])
        mock.expect(:call, nil, [:user, :step])

        action.call(user: :user, step: :step).deliver_now
        action.call(user: :user, step: :step).deliver_later

        assert_mock mock
      end

      test "block actions can be called with one argument" do
        mock = MiniTest::Mock.new
        block = Proc.new { |u| mock.call(u) }
        action = Actions::Block.build(block)

        mock.expect(:call, nil, [:user])
        action.call(user: :user, step: :step).deliver_now
        assert_mock mock
      end

      test "block actions can be called with no arguments" do
        mock = MiniTest::Mock.new
        block = Proc.new { mock.call }
        action = Actions::Block.build(block)

        mock.expect(:call, nil, [])
        action.call(user: :user, step: :step).deliver_now
        assert_mock mock
      end
    end
  end
end
