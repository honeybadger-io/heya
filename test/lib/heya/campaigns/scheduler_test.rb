require "test_helper"

module Heya
  module Campaigns
    class SchedulerTest < ActiveSupport::TestCase
      def run_once
        Scheduler.new.run
      end

      def run_twice
        2.times {
          run_once
        }
      end

      def setup
        Heya.campaigns = []
      end

      test "it processes campaign actions in order" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default action: action
          user_type "Contact"
          step :one, wait: 5.days
          step :two, wait: 3.days
          step :three, wait: 2.days
        }
        contact = contacts(:one)
        campaign.add(contact, send_now: false)

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(6.days.from_now)
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign.steps.first,
        }])
        run_twice
        assert_mock action

        Timecop.travel(2.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign.steps.second,
        }])
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign.steps.third,
        }])
        run_twice
        assert_mock action
      end

      test "it skips actions that don't match segments" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type "Contact"
          step :one, segment: ->(u) { u.traits["foo"] == "bar" }
        }
        contact = contacts(:one)
        campaign.add(contact, send_now: false)

        run_twice
        assert_mock action
      end

      test "it processes actions that match segments" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type "Contact"
          step :one, segment: ->(u) { u.traits["foo"] == "bar" }
        }
        contact = contacts(:one)
        contact.update_attribute(:traits, {foo: "bar"})
        campaign.add(contact, send_now: false)

        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign.steps.first,
        }])

        run_twice
        assert_mock action
      end

      test "it waits for segments to match" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default action: action
          user_type "Contact"
          step :one, wait: 0
          step :two, wait: 2.days, segment: ->(u) { u.traits["foo"] == "bar" }
          step :three, wait: 1.day, segment: ->(u) { u.traits["bar"] == "baz" }
        }
        contact = contacts(:one)
        contact.update_attribute(:traits, {bar: "baz"})
        campaign.add(contact, send_now: false)

        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign.steps.first,
        }])
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign.steps.third,
        }])
        run_once
        assert_mock action
      end

      test "it skips actions that don't match default segments" do
        action = Minitest::Mock.new
        class TestContact < Contact
          default_segment { |u| u.traits["foo"] == "bar" }
        end
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type TestContact
          step :one
        }
        contact = contacts(:one).becomes(TestContact)
        campaign.add(contact, send_now: false)

        run_once
        assert_mock action
      end

      test "it processes actions that match default segments" do
        action = Minitest::Mock.new
        class TestContact < Contact
          default_segment { |u| u.traits["foo"] == "bar" }
        end
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type TestContact
          step :one
        }
        contact = contacts(:one).becomes(TestContact)
        contact.update_attribute(:traits, {foo: "bar"})
        campaign.add(contact, send_now: false)

        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign.steps.first,
        }])

        run_once
        assert_mock action
      end

      test "it skips actions that don't match campaign segment" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type "Contact"
          segment { |u| u.traits["foo"] == "foo" }
          step :one
        }
        contact = contacts(:one)
        campaign.add(contact, send_now: false)

        run_once

        assert_mock action
      end

      test "it processes actions that match campaign segment" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type "Contact"
          segment { |u| u.traits["foo"] == "foo" }
          step :one
        }
        contact = contacts(:one)
        contact.update_attribute(:traits, {foo: "foo"})
        campaign.add(contact, send_now: false)

        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign.steps.first,
        }])

        run_once

        assert_mock action
      end

      test "it removes contacts from campaign at end" do
        campaign = create_test_campaign {
          default wait: 0
          user_type "Contact"
          step :one
          step :two
          step :three
        }
        contact = contacts(:one)
        campaign.add(contact, send_now: false)

        assert CampaignMembership.where(campaign_gid: campaign.gid, user: contact).exists?

        run_once

        refute CampaignMembership.where(campaign_gid: campaign.gid, user: contact).exists?
      end

      test "it processes campaign actions concurrently" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type "Contact"
          step :one
        }
        contact = contacts(:one)
        campaign.add(contact, send_now: false)

        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign.steps.first,
        }])

        # Make sure missing constants are autoloaded >:]
        run_once

        20.times.map {
          Thread.new {
            run_once
          }
        }.each(&:join)

        assert_mock action
      end

      test "it processes multiple campaign actions in order" do
        action = Minitest::Mock.new
        campaign1 = create_test_campaign("TestCampaign1") {
          default action: action
          user_type "Contact"
          step :one, wait: 5.days
        }
        campaign2 = create_test_campaign("TestCampaign2") {
          default action: action
          user_type "Contact"
          step :one, wait: 3.days
        }
        campaign3 = create_test_campaign("TestCampaign3") {
          default action: action
          user_type "Contact"
          step :one, wait: 2.days
        }
        contact = contacts(:one)
        campaign1.add(contact, send_now: false)
        campaign2.add(contact, send_now: false)
        campaign3.add(contact, send_now: false)

        Heya.configure do |config|
          config.priority = [
            campaign1,
            campaign2,
            campaign3,
          ]
        end

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(6.days.from_now)
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign1.steps.first,
        }])
        run_twice
        assert_mock action

        Timecop.travel(2.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign2.steps.first,
        }])
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign3.steps.first,
        }])
        run_twice
        assert_mock action
      end

      test "it processes concurrent campaign actions concurrently" do
        action = Minitest::Mock.new
        campaign1 = create_test_campaign("TestCampaign1") {
          default action: action
          user_type "Contact"
          step :one, wait: 5.days
          step :two, wait: 2.days
          step :three, wait: 1.days
        }
        campaign2 = create_test_campaign("TestCampaign2") {
          default action: action
          user_type "Contact"
          step :one, wait: 3.days
          step :two, wait: 3.days
        }
        campaign3 = create_test_campaign("TestCampaign3") {
          default action: action
          user_type "Contact"
          step :one, wait: 2.days
        }
        contact = contacts(:one)
        campaign1.add(contact, send_now: false, concurrent: true)
        campaign2.add(contact, send_now: false)
        campaign3.add(contact, send_now: false)

        Timecop.travel(2.days.from_now)
        run_once
        assert_mock action

        Timecop.travel(3.days.from_now)
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign1.steps.first,
        }])
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign2.steps.first,
        }])
        run_once
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_once
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign1.steps.second,
        }])
        run_once
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign1.steps.third,
        }])
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign2.steps.second,
        }])
        run_once
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_once
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, NullMail, [{
          user: contact,
          step: campaign3.steps.first,
        }])
        run_once
        assert_mock action
      end
    end
  end
end
