# frozen_string_literal: true

require "test_helper"

module Heya
  module Campaigns
    class BaseTest < ActiveSupport::TestCase
      TestError = Class.new(StandardError)
      ExpectedError = Class.new(StandardError)

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
        parent = Class.new(Base) {
          default wait: 5.years,
                  from: nil
        }

        child = Class.new(parent) {
          default from: "expected"
        }

        assert_not_equal Base.__defaults, parent.__defaults
        assert_not_equal Base.__defaults, child.__defaults

        assert_equal 5.years, parent.__defaults[:wait]
        assert_nil parent.__defaults[:from]

        assert_equal 5.years, child.__defaults[:wait]
        assert_equal "expected", child.__defaults[:from]
      end

      test "it has class segments" do
        assert_equal [], Base.__segments
      end

      test "it allows subclasses to change segments" do
        block_one = -> { :one }
        block_two = -> { :two }

        parent = Class.new(Base) {
          segment(&block_one)
        }

        child = Class.new(parent) {
          segment(&block_two)
        }

        assert_equal [block_one], parent.__segments
        assert_equal [block_two, block_one], child.__segments
      end

      test "it sets default user_type" do
        assert_equal "Contact", Base.user_type
      end

      test "it allows subclasses to change user_type" do
        campaign = Class.new(Base) {
          user_type "Expected"
        }

        assert_equal "Expected", campaign.user_type
        assert_not_equal Base.user_type, campaign.user_type
      end

      test "it allows subclasses to inherit user_type" do
        parent = Class.new(Base) {
          user_type "Expected"
        }
        child = Class.new(parent) {}

        assert_equal "Expected", child.user_type
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

      test "#add sends first step in campaign by default" do
        action = Minitest::Mock.new
        campaign = Class.new(Base) {
          default action: action
          user_type "Contact"
          step :one, wait: 0
          def self.name
            "TestCampaign"
          end
        }
        contact = contacts(:one)

        action.expect(:new, NullMail, [{
          user: contact,
          step: campaign.steps.first
        }])

        campaign.add(contact)
        assert_mock action
      end

      test "#add skips first step in campaign with send_now: false" do
        action = Minitest::Mock.new
        campaign = Class.new(Base) {
          default action: action
          user_type "Contact"
          step :one, wait: 0
          def self.name
            "TestCampaign"
          end
        }
        contact = contacts(:one)

        campaign.add(contact, send_now: false)
        assert_mock action
      end

      test "#add skips first step in campaign with wait > 0" do
        action = Minitest::Mock.new
        campaign = Class.new(Base) {
          default action: action
          user_type "Contact"
          step :one, wait: 1
          def self.name
            "TestCampaign"
          end
        }
        contact = contacts(:one)

        campaign.add(contact)
        assert_mock action
      end

      test "#add skips user when already in campaign" do
        campaign = create_test_campaign {
          user_type "Contact"
        }
        contact = contacts(:one)

        assert campaign.add(contact, send_now: false)
        refute campaign.add(contact)
      end

      test "#add restarts campaign when already in campaign and restart is true" do
        campaign = create_test_campaign {
          user_type "Contact"
        }
        contact = contacts(:one)

        assert campaign.add(contact, send_now: false)
        assert campaign.add(contact, restart: true)
      end

      test "#add requires campaign segment to match" do
        campaign = create_test_campaign {
          user_type "Contact"
          segment { |u| u.traits["foo"] == "bar" }
        }
        contact = contacts(:one)

        refute campaign.add(contact)

        contact.update_attribute(:traits, {foo: "bar"})

        assert campaign.add(contact)
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
        action = Class.new(Action) {
          def build
            :expected
          end
        }
        campaign = Class.new(Base) {
          step :expected_name, action: action
        }

        assert_equal :expected, campaign.expected_name(:user)
      end

      test "doesn't allow existing method names as step names" do
        assert_raise RuntimeError, /Invalid/ do
          Class.new(Base) {
            step :default
          }
        end
      end

      test "executes block actions" do
        mock = MiniTest::Mock.new
        campaign = Class.new(Base) {
          step :expected_name do |user, step|
            mock.call(user, step.name)
          end
        }
        user = Object.new

        mock.expect(:call, nil, [user, "expected_name"])

        campaign.expected_name(user).deliver

        assert_mock mock
      end

      test "#handle_exception handles exceptions with rescuable" do
        campaign = Class.new(Base) {
          default wait: 5.years

          rescue_from TestError do
            raise ExpectedError.new("expected test error")
          end
        }

        assert_raises(ExpectedError) do
          campaign.handle_exception(TestError.new("unexpected test error"))
        end
      end

      test "#handle_exception raises unhandled exceptions" do
        campaign = Class.new(Base) {
          default wait: 5.years
        }

        assert_raises(ExpectedError) do
          campaign.handle_exception(ExpectedError.new("expected test error"))
        end
      end
    end
  end
end
