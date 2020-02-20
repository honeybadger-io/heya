require "test_helper"

class Heya::ConfigTest < ActiveSupport::TestCase
  test "has default priority" do
    assert_equal [], Heya::Config.new.campaigns.priority
  end

  test "assigns priority" do
    config = Heya::Config.new
    config.campaigns.priority = ["Expected"]
    assert_equal ["Expected"], config.campaigns.priority
  end

  test "has default user_type" do
    assert_equal "User", Heya::Config.new.user_type
  end

  test "assigns user_type" do
    config = Heya::Config.new
    config.user_type = "ExpectedUser"
    assert_equal "ExpectedUser", config.user_type
  end

  test "has default_options" do
    assert_equal({}, Heya::Config.new.campaigns.default_options)
  end

  test "assigns default_options" do
    config = Heya::Config.new
    config.campaigns.default_options = {from: "expected@example.com"}
    assert_equal({from: "expected@example.com"}, config.campaigns.default_options)
  end

  test "it registers campaigns once" do
    klass = Object.new
    begin
      Heya.register_campaign(klass)
      Heya.register_campaign(klass)
      Heya.register_campaign(klass)

      assert_equal [klass], Heya.campaigns.select {|k| k == klass }
    ensure
      Heya.campaigns.delete(klass)
    end
  end
end
