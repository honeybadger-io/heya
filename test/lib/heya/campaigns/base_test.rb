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

      test "it lazily creates a new campaign model" do
        klass = assert_no_difference("Heya::Campaign.count") {
          Class.new(Base) {
            def self.name
              "TestCampaign"
            end
          }
        }

        assert_difference("Heya::Campaign.count") do
          model = klass.campaign.model

          assert_equal "TestCampaign", model.name
        end
      end

      test "it lazily creates message models" do
        klass = assert_no_difference("Heya::Message.count") {
          Class.new(Base) {
            default contact_class: "Contact"

            step :one
            step :two
          }
        }

        assert_difference("Heya::Message.count") do
          assert_equal "one", klass.messages.first.model.name
        end

        assert_difference("Heya::Message.count") do
          assert_equal "two", klass.messages.second.model.name
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
          assert_equal heya_campaigns(:one), klass.campaign.model
        end
      end

      test "it lazily finds existing message models" do
        klass = assert_no_difference("Heya::Message.count") {
          Class.new(Base) {
            def self.name
              "FirstCampaign"
            end

            default contact_class: "Contact"

            step :one
            step :two
          }
        }

        assert_no_difference("Heya::Message.count") do
          assert_equal heya_messages(:one), klass.messages.first.model
        end

        assert_no_difference("Heya::Message.count") do
          assert_equal heya_messages(:two), klass.messages.second.model
        end
      end
    end
  end
end
