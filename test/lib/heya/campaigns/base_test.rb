require "test_helper"

module Heya
  module Campaigns
    class BaseTest < ActiveSupport::TestCase
      test "it sets class defaults" do
        assert_kind_of Hash, Base.defaults
      end

      test "it allows subclasses to change defaults" do
        klass = Class.new(Base) {
          default wait: 5.years
        }

        assert_equal 5.years, klass.defaults[:wait]
        assert_not_equal Base.defaults, klass.defaults
      end

      test "it sets class segment" do
        assert_kind_of Proc, Base.segment
      end

      test "it allows subclasses to change segment" do
        block = -> { where(id: 1) }
        klass = Class.new(Base) {
          segment(&block)
        }

        assert_equal block, klass.segment
        assert_not_equal Base.segment, klass.segment
      end

      test "it sets default contact_type" do
        assert_equal "User", Base.contact_type
      end

      test "it allows subclasses to change contact_type" do
        klass = Class.new(Base) {
          contact_type "Contact"
        }

        assert_equal "Contact", klass.contact_type
        assert_not_equal Base.contact_type, klass.contact_type
      end

      test "it lazily creates a new campaign model" do
        klass = assert_no_difference("Heya::Campaign.count") {
          Class.new(Base) {
            def self.name
              "TestCampaign"
            end
          }
        }

        assert_difference("Heya::Campaign.count") do
          assert_equal "TestCampaign", klass.campaign.name
        end
      end

      test "it lazily creates message models" do
        klass = assert_no_difference("Heya::Message.count") {
          Class.new(Base) {
            contact_type "Contact"

            step :one
            step :two
          }
        }

        assert_no_difference("Heya::Message.count") do
          assert_equal 0, klass.messages.size
        end

        assert_difference("Heya::Message.count", 2) do
          klass.load_model
          assert_equal 2, klass.messages.size
        end
      end

      test "it lazily finds an existing campaign model" do
        klass = assert_no_difference("Heya::Campaign.count") {
          Class.new(Base) {
            def self.name
              "FirstCampaign"
            end
          }
        }

        assert_no_difference("Heya::Campaign.count") do
          assert_equal heya_campaigns(:one), klass.campaign
        end
      end

      test "it lazily finds existing message models" do
        klass = assert_no_difference("Heya::Message.count") {
          Class.new(Base) {
            def self.name
              "FirstCampaign"
            end

            contact_type "Contact"

            step :one
            step :two
          }
        }

        assert_no_difference("Heya::Message.count") do
          klass.load_model
        end

        assert_equal heya_messages(:one), klass.messages.first
        assert_equal heya_messages(:two), klass.messages.second
      end
    end
  end
end
