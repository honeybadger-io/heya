require "test_helper"

module Heya
  module Campaigns
    class BaseTest < ActiveSupport::TestCase
      def setup
        Heya.campaigns = []
      end

      test "it adds the campaign to Heya.campaigns" do
        campaign = Class.new(Base) {
          default wait: 5.years
        }

        assert_includes Heya.campaigns, campaign
      end

      test "it sets class defaults" do
        assert_kind_of Hash, Base.__defaults
      end

      test "it allows subclasses to change defaults" do
        campaign = Class.new(Base) {
          default wait: 5.years
        }

        assert_equal 5.years, campaign.__defaults[:wait]
        assert_not_equal Base.__defaults, campaign.__defaults
      end

      test "it has class segment" do
        assert_nil Base.segment
      end

      test "it allows subclasses to change segment" do
        block = -> { where(id: 1) }
        campaign = Class.new(Base) {
          segment(&block)
        }

        assert_equal block, campaign.segment
        assert_not_equal Base.segment, campaign.segment
      end

      test "it sets default user_type" do
        assert_equal "User", Base.user_type
      end

      test "it allows subclasses to change user_type" do
        campaign = Class.new(Base) {
          user_type "Contact"
        }

        assert_equal "Contact", campaign.user_type
        assert_not_equal Base.user_type, campaign.user_type
      end

      test "it adds and removes users from campaign" do
        campaign = Class.new(Base) {
          user_type "Contact"
          def self.name
            "Test"
          end
        }
        membership = CampaignMembership.where(user: contacts(:one), campaign_gid: campaign.gid)

        refute membership.exists?

        campaign.add(contacts(:one))

        assert membership.exists?

        campaign.remove(contacts(:one))

        refute membership.exists?
      end

      test "it finds users for campaign" do
        campaign = Class.new(Base) {
          user_type "Contact"
          def self.name
            "Test"
          end
        }
        CampaignMembership.create(user: contacts(:one), campaign_gid: campaign.gid)
        CampaignMembership.create(user: contacts(:one), campaign_gid: "gid://dummy/Other/1")

        assert_equal [contacts(:one)], campaign.users
      end

      test "it creates steps with String names" do
        campaign = Class.new(Base) {
          step :expected_name
        }
        assert_equal "expected_name", campaign.steps.first.name
      end

      test "generates an action method for each step" do
        mock = MiniTest::Mock.new
        campaign = Class.new(Base) {
          step :expected_name, action: ->(user:, step:) { mock.call(user, step.name) }
        }
        user = Object.new

        mock.expect(:call, nil, [user, "expected_name"])

        campaign.expected_name(user)
      end

      test "doesn't allow existing method names as step names" do
        assert_raise RuntimeError, /Invalid/ do
          Class.new(Base) {
            step :default
          }
        end
      end
    end
  end
end
