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

      test "it sets class segment" do
        assert_kind_of Proc, Base.segment
      end

      test "it allows subclasses to change segment" do
        block = -> { where(id: 1) }
        campaign = Class.new(Base) {
          segment(&block)
        }

        assert_equal block, campaign.segment
        assert_not_equal Base.segment, campaign.segment
      end

      test "it sets default contact_type" do
        assert_equal "User", Base.contact_type
      end

      test "it allows subclasses to change contact_type" do
        campaign = Class.new(Base) {
          contact_type "Contact"
        }

        assert_equal "Contact", campaign.contact_type
        assert_not_equal Base.contact_type, campaign.contact_type
      end

      test "it adds and removes contacts from campaign" do
        campaign = Class.new(Base) {
          contact_type "Contact"
          def self.name
            "Test"
          end
        }
        membership = CampaignMembership.where(contact: contacts(:one), campaign_gid: campaign.gid)

        refute membership.exists?

        campaign.add(contacts(:one))

        assert membership.exists?

        campaign.remove(contacts(:one))

        refute membership.exists?
      end

      test "it finds contacts for campaign" do
        campaign = Class.new(Base) {
          contact_type "Contact"
          def self.name
            "Test"
          end
        }
        CampaignMembership.create(contact: contacts(:one), campaign_gid: campaign.gid)
        CampaignMembership.create(contact: contacts(:one), campaign_gid: "gid://dummy/Other/1")

        assert_equal [contacts(:one)], campaign.contacts
      end
    end
  end
end
