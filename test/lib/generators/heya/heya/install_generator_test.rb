require "test_helper"
require "generators/heya/install/install_generator"

module Heya
  class Heya::InstallGeneratorTest < Rails::Generators::TestCase
    tests Heya::InstallGenerator
    destination Rails.root.join("tmp/generators")
    setup :prepare_destination

    test "generator runs without errors" do
      assert_nothing_raised do
        run_generator
      end
    end
  end
end
