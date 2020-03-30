# frozen_string_literal: true

require "test_helper"

class Heya::Test < ActiveSupport::TestCase
  class User
    def foo
      "foo"
    end

    def bar
      "bar"
    end

    def true?
      true
    end

    def false?
      false
    end
  end

  test "#in_segments? returns true when all segments match user" do
    assert Heya.in_segments?(User.new, ->(u) { u.foo == "foo" }, ->(u) { u.bar == "bar" })
  end

  test "#in_segments? returns false when one or more segments don't match user" do
    refute Heya.in_segments?(User.new, ->(u) { u.foo == "foo" }, ->(u) { u.bar == "baz" })
  end

  test "#in_segments? matches symbol segments" do
    assert Heya.in_segments?(User.new, :true?)
    refute Heya.in_segments?(User.new, :false?)
  end

  test "#configure yields configuration object" do
    config = Minitest::Mock.new

    config.expect(:value=, nil, ["expected value"])

    Heya.stub(:config, config) do
      Heya.configure do |config|
        config.value = "expected value"
      end
    end

    assert_mock config
  end

  test "#config is a Config" do
    assert_kind_of Heya::Config, Heya.config
  end

  test "#verify_license! logs no license by default" do
    expected = Minitest::Mock.new
    expected.expect(:call, nil, [/non-profit/])
    Heya.stub(:puts, ->(msg) { expected.call(msg) }) do
      Heya.verify_license!
    end
    assert_mock expected
  end

  test "#verify_license! is silent with valid license" do
    not_expected = Minitest::Mock.new

    license_path = TMP_PATH.join("Heya.heya-license")
    File.open(license_path, "w") { |f| f.write(generate_license) }
    Heya.config.stub(:license_file, license_path) do
      mock_license_key do
        Heya.stub(:puts, ->(msg) { not_expected.call(msg) }) do
          Heya.verify_license!
        end
      end
    end

    assert_mock not_expected
  end

  test "#verify_license! warns expired license" do
    expected = Minitest::Mock.new
    expected.expect(:call, nil, [/expired/])

    license_path = TMP_PATH.join("Heya.heya-license")
    File.open(license_path, "w") { |f| f.write(generate_license(starts_at: 2.days.ago.to_date, expires_at: 1.day.ago.to_date)) }
    Heya.config.stub(:license_file, license_path) do
      mock_license_key do
        Heya.stub(:warn, ->(msg) { expected.call(msg) }) do
          Heya.verify_license!
        end
      end
    end

    assert_mock expected
  end

  test "#verify_license! warns over user count" do
    expected = Minitest::Mock.new
    expected.expect(:call, nil, [/exceeds/])

    license_path = TMP_PATH.join("Heya.heya-license")
    File.open(license_path, "w") { |f| f.write(generate_license(user_count: 1)) }
    Heya.config.stub(:license_file, license_path) do
      mock_license_key do
        Heya.stub(:warn, ->(msg) { expected.call(msg) }) do
          Heya.verify_license!
        end
      end
    end

    assert_mock expected
  end

  test "#verify_license! is silent when under user count" do
    not_expected = Minitest::Mock.new

    license_path = TMP_PATH.join("Heya.heya-license")
    File.open(license_path, "w") { |f| f.write(generate_license(user_count: 50)) }
    Heya.config.stub(:license_file, license_path) do
      mock_license_key do
        Heya.stub(:warn, ->(msg) { not_expected.call(msg) }) do
          Heya.verify_license!
        end
      end
    end

    assert_mock not_expected
  end
end
