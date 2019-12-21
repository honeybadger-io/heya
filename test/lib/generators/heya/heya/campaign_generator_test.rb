require "test_helper"
require "generators/heya/campaign/campaign_generator"

module Heya
  class Heya::CampaignGeneratorTest < Rails::Generators::TestCase
    tests Heya::CampaignGenerator
    destination Rails.root.join("tmp/generators")
    setup :prepare_destination

    test "generator runs without errors" do
      assert_nothing_raised do
        run_generator ["arguments"]
      end
    end
  end
end
