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
end
