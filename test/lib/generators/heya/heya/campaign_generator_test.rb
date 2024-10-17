# frozen_string_literal: true

require "test_helper"
require "generators/heya/campaign/campaign_generator"

module Heya
  class Heya::CampaignGeneratorTest < Rails::Generators::TestCase
    tests Heya::CampaignGenerator
    destination Rails.root.join("tmp/generators")
    setup :prepare_destination

    test "generator runs without errors" do
      assert_nothing_raised do
        run_generator %w[arguments welcome:0]
      end
      assert_file "test/mailers/previews/arguments_campaign_preview.rb"
      assert_file "app/views/heya/campaign_mailer/arguments_campaign/welcome.html.erb"
      assert_file "app/views/heya/campaign_mailer/arguments_campaign/welcome.text.erb"
    end

    test "supports flag --skip-previews" do
      assert_nothing_raised do
        run_generator %w[arguments --skip-previews]
      end
      assert_no_file "test/mailers/previews/arguments_campaign_preview.rb"
    end

    test "supports flag --skip-views" do
      assert_nothing_raised do
        run_generator %w[arguments welcome:0 --skip-views]
      end
      assert_no_file "app/views/heya/campaign_mailer/arguments_campaign/welcome.html.erb"
      assert_no_file "app/views/heya/campaign_mailer/arguments_campaign/welcome.text.erb"
    end
  end
end
