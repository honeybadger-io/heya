# frozen_string_literal: true

require "test_helper"

class HeyaTest < ActionDispatch::IntegrationTest
  test "it sets default config" do
    assert_equal Rails.root.join("config/Heya.heya-license"), Heya.config.license_file
  end

  test "it sets the encryption key" do
    key = OpenSSL::PKey::RSA.new(File.read(File.expand_path("../../../license_key.pub", __FILE__)))
    assert_equal key.to_s, Heya::License.encryption_key.to_s
  end
end
