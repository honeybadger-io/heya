# frozen_string_literal: true

require "test_helper"

module Heya
  module Campaigns
    module Actions
      class BlockTest < ActiveSupport::TestCase
        test "block actions can be called with one argument" do
          mock = MiniTest::Mock.new
          block = proc { |u| mock.call(u) }
          step = OpenStruct.new(params: {"block" => block})
          action = Block.new(user: :user, step: step)

          mock.expect(:call, nil, [:user])
          action.deliver_now
          assert_mock mock
        end

        test "block actions can be called with no arguments" do
          mock = MiniTest::Mock.new
          block = proc { mock.call }
          step = OpenStruct.new(params: {"block" => block})
          action = Block.new(user: :user, step: step)

          mock.expect(:call, nil, [])
          action.deliver_now
          assert_mock mock
        end
      end
    end
  end
end
