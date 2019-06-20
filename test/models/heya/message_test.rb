require "test_helper"

module Heya
  class MessageTest < ActiveSupport::TestCase
    test "it has assignable properties" do
      message = heya_messages(:one)
      message.properties = {"foo" => "bar"}

      assert message.properties == {"foo" => "bar"}
    end
  end
end
