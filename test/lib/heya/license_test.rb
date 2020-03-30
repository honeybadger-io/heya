# frozen_string_literal: true

require "test_helper"

class Heya::LicenseTest < ActiveSupport::TestCase
  test "it is valid" do
    mock_license_key do
      license = Heya::License.import(generate_license)
      refute license.expired?
    end
  end

  test "it is expired" do
    mock_license_key do
      license = Heya::License.import(generate_license(starts_at: 2.days.ago.to_date, expires_at: 1.day.ago.to_date))
      assert license.expired?
    end
  end

  test "it encodes user_count" do
    mock_license_key do
      license = Heya::License.import(generate_license(user_count: 3))
      assert_equal 3, license.restrictions[:user_count]
    end
  end
end
