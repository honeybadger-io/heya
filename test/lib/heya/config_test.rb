require "test_helper"

class Heya::ConfigTest < ActiveSupport::TestCase
  test "has default user_type" do
    assert_equal "User", Heya::Config.new.user_type
  end

  test "assigns user_type" do
    config = Heya::Config.new
    config.user_type = "ExpectedUser"
    assert_equal "ExpectedUser", config.user_type
  end

  test "has default priority" do
    assert_equal [], Heya::Config.new.priority
  end

  test "assigns priority" do
    config = Heya::Config.new
    config.priority = ["Expected"]
    assert_equal ["Expected"], config.priority
  end

  test "has default from" do
    assert_nil Heya::Config.new.from
  end

  test "assigns from" do
    config = Heya::Config.new
    config.from = "expected@example.com"
    assert_equal "expected@example.com", config.from
  end
end
