# frozen_string_literal: true

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
        action.expect(:new, NullMail,
          user: contact,
          step: campaign.steps.first)
        run_twice
        assert_mock action

        Timecop.travel(2.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:new, NullMail,
          user: contact,
          step: campaign.steps.second)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:new, NullMail,
          user: contact,
          step: campaign.steps.third)
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

        action.expect(:new, NullMail,
          user: contact,
          step: campaign.steps.first)

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

        action.expect(:new, NullMail,
          user: contact,
          step: campaign.steps.first)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:new, NullMail,
          user: contact,
          step: campaign.steps.third)
        run_twice
        assert_mock action
      end

      test "it skips actions that don't match parent segments" do
        action = Minitest::Mock.new
        parent = create_test_campaign {
          segment { |u| u.traits["foo"] == "bar" }
        }
        child = create_test_campaign(name: "ChildCampaign", parent: parent) {
          default wait: 0, action: action
          user_type "Contact"
          step :one
        }
        contact = contacts(:one)
        child.add(contact, send_now: false)

        run_once
        assert_mock action
      end

      test "it processes actions that match parent segments" do
        action = Minitest::Mock.new
        parent = create_test_campaign {
          segment { |u| u.traits["foo"] == "bar" }
        }
        child = create_test_campaign(name: "ChildCampaign", parent: parent) {
          default wait: 0, action: action
          user_type "Contact"
          step :one
        }
        contact = contacts(:one)
        contact.update_attribute(:traits, {foo: "bar"})
        child.add(contact, send_now: false)

        action.expect(:new, NullMail,
          user: contact,
          step: child.steps.first)

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

        action.expect(:new, NullMail,
          user: contact,
          step: campaign.steps.first)

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
        run_once
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

        action.expect(:new, NullMail,
          user: contact,
          step: campaign.steps.first)

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
        campaign1 = create_test_campaign(name: "TestCampaign1") {
          default action: action
          user_type "Contact"
          step :one, wait: 5.days
        }
        campaign2 = create_test_campaign(name: "TestCampaign2") {
          default action: action
          user_type "Contact"
          step :one, wait: 3.days
        }
        campaign3 = create_test_campaign(name: "TestCampaign3") {
          default action: action
          user_type "Contact"
          step :one, wait: 2.days
        }
        contact = contacts(:one)
        campaign3.add(contact, send_now: false)
        campaign2.add(contact, send_now: false)
        campaign1.add(contact, send_now: false)

        Heya.configure do |config|
          config.campaigns.priority = [
            "TestCampaign1",
            "TestCampaign2",
            "TestCampaign3"
          ]
        end

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(6.days.from_now)
        action.expect(:new, NullMail,
          user: contact,
          step: campaign1.steps.first)
        run_twice
        assert_mock action

        Timecop.travel(2.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:new, NullMail,
          user: contact,
          step: campaign2.steps.first)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:new, NullMail,
          user: contact,
          step: campaign3.steps.first)
        run_twice
        assert_mock action
      end

      test "it processes concurrent campaign actions concurrently" do
        action = Minitest::Mock.new
        campaign1 = create_test_campaign(name: "TestCampaign1") {
          default action: action
          user_type "Contact"
          step :one, wait: 5.days
          step :two, wait: 2.days
          step :three, wait: 1.days
        }
        campaign2 = create_test_campaign(name: "TestCampaign2") {
          default action: action
          user_type "Contact"
          step :one, wait: 3.days
          step :two, wait: 3.days
        }
        campaign3 = create_test_campaign(name: "TestCampaign3") {
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
        action.expect(:new, NullMail,
          user: contact,
          step: campaign1.steps.first)
        action.expect(:new, NullMail,
          user: contact,
          step: campaign2.steps.first)
        run_once
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_once
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:new, NullMail,
          user: contact,
          step: campaign1.steps.second)
        run_once
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:new, NullMail,
          user: contact,
          step: campaign1.steps.third)
        action.expect(:new, NullMail,
          user: contact,
          step: campaign2.steps.second)
        run_once
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_once
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:new, NullMail,
          user: contact,
          step: campaign3.steps.first)
        run_once
        assert_mock action
      end

      test "it deletes orphaned campaign memberships" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          user_type "Contact"
          step :one, wait: 0
          step :two, wait: 0
          step :three, wait: 0
        }
        contact1 = contacts(:one)
        contact2 = contacts(:two)
        campaign.add(contact1, send_now: false)
        campaign.add(contact2, send_now: false)
        membership = CampaignMembership.where(
          campaign_gid: campaign.gid,
          user_type: "Contact"
        )

        run_once

        assert membership.where(user_id: contact1.id).exists?
        assert membership.where(user_id: contact2.id).exists?

        contact1.destroy

        run_once

        refute membership.where(user_id: contact1.id).exists?
        assert membership.where(user_id: contact2.id).exists?

        assert_mock action
      end

      test "it immediately skips steps that have receipts" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default action: action
          user_type "Contact"
          step :one, wait: 0
          step :two, wait: 3.days
          step :three, wait: 2.days
        }

        contact = contacts(:one)

        CampaignReceipt.create!(
          user: contact,
          step_gid: campaign.steps[1].gid
        )

        action.expect(:new, NullMail,
          user: contact,
          step: campaign.steps.first)

        campaign.add(contact)

        membership = CampaignMembership
          .where(user: contact, campaign_gid: campaign.gid)
          .first

        assert_equal campaign.steps[2].gid, membership.step_gid
      end

      test "it skips steps that have receipts during a global run" do
        campaign = create_test_campaign {
          default wait: 0
          user_type "Contact"
          step :one
          step :two
          step :three, wait: 1.day
        }
        contact = contacts(:one)
        CampaignReceipt.create!(user: contact, step_gid: campaign.steps.second.gid)

        campaign.add(contact, send_now: false)
        run_once

        membership = CampaignMembership.where(user: contact, campaign_gid: campaign.gid).first
        assert_equal campaign.steps.third.gid, membership.step_gid
      end

      test "it removes the user when a halting campaign segment stops matching" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type "Contact"
          halt true
          segment ->(u) { u.traits["foo"] == "bar" }
          step :one
          step :two
          step :three, wait: 1.day
        }
        contact = contacts(:one)
        contact.update_attribute(:traits, {foo: "bar"})

        action.expect(:new, NullMail,
          user: contact,
          step: campaign.steps.first)

        campaign.add(contact, send_now: false)
        run_once
        assert_mock action

        membership = CampaignMembership.where(user: contact, campaign_gid: campaign.gid).first
        assert_equal campaign.steps.second.gid, membership.step_gid

        contact.update_attribute(:traits, {foo: "other"})
        run_once

        refute CampaignMembership.where(user: contact, campaign_gid: campaign.gid).exists?
      end

      test "it removes the user when a step's own segment stops matching" do
        campaign = create_test_campaign {
          default wait: 0
          user_type "Contact"
          halt true
          segment ->(u) { u.traits["eligible"] == "yes" }
          step :one, segment: ->(u) { u.traits["foo"] == "bar" }
          step :two, wait: 1.day
        }
        contact = contacts(:one)
        contact.update_attribute(:traits, {eligible: "yes"})

        campaign.add(contact, send_now: false)
        run_once

        refute CampaignMembership.where(user: contact, campaign_gid: campaign.gid).exists?
      end

      test "it removes a user who opted into halting via add" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type "Contact"
          step :one, segment: ->(u) { u.traits["foo"] == "bar" }
          step :two
        }
        contact = contacts(:one)
        campaign.add(contact, send_now: false, halt: true)

        run_once
        assert_mock action

        refute CampaignMembership.where(user: contact, campaign_gid: campaign.gid).exists?
      end

      test "it keeps a user who opted out of halting on a halting campaign" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type "Contact"
          halt true
          step :one, segment: ->(u) { u.traits["foo"] == "bar" }
          step :two
        }
        contact = contacts(:one)
        campaign.add(contact, send_now: false, halt: false)

        run_once
        assert_mock action

        membership = CampaignMembership.where(user: contact, campaign_gid: campaign.gid).first
        assert_equal campaign.steps.second.gid, membership.step_gid
      end

      test "it keeps a non-halting user whose segment doesn't match" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type "Contact"
          step :one, segment: ->(u) { u.traits["foo"] == "bar" }
          step :two
        }
        contact = contacts(:one)
        campaign.add(contact, send_now: false)

        run_once
        assert_mock action

        membership = CampaignMembership.where(user: contact, campaign_gid: campaign.gid).first
        assert_equal campaign.steps.second.gid, membership.step_gid
      end

      test "it delivers to a halting user whose segment matches" do
        action = Minitest::Mock.new
        campaign = create_test_campaign {
          default wait: 0, action: action
          user_type "Contact"
          halt true
          step :one, segment: ->(u) { u.traits["foo"] == "bar" }
          step :two, wait: 1.day
        }
        contact = contacts(:one)
        contact.update_attribute(:traits, {foo: "bar"})

        action.expect(:new, NullMail,
          user: contact,
          step: campaign.steps.first)

        campaign.add(contact, send_now: false)
        run_once
        assert_mock action

        membership = CampaignMembership.where(user: contact, campaign_gid: campaign.gid).first
        assert_equal campaign.steps.second.gid, membership.step_gid
      end

      test "it creates no receipt for the step that halted" do
        campaign = create_test_campaign {
          default wait: 0
          user_type "Contact"
          halt true
          step :one, segment: ->(u) { u.traits["foo"] == "bar" }
          step :two, wait: 1.day
        }
        contact = contacts(:one)
        campaign.add(contact, send_now: false)

        run_once

        refute CampaignMembership.where(user: contact, campaign_gid: campaign.gid).exists?
        assert_empty CampaignReceipt.where(user: contact, step_gid: campaign.steps.first.gid)
      end

      test "it removes the user even when the current step already has a receipt" do
        campaign = create_test_campaign {
          default wait: 0
          user_type "Contact"
          halt true
          segment ->(u) { u.traits["foo"] == "bar" }
          step :one
          step :two
        }
        contact = contacts(:one)
        contact.update_attribute(:traits, {foo: "bar"})
        campaign.add(contact, send_now: false)

        first_step_gid = campaign.steps.first.gid
        CampaignReceipt.create!(user: contact, step_gid: first_step_gid, sent_at: Time.now.utc)

        contact.update_attribute(:traits, {foo: "other"})
        run_once

        refute CampaignMembership.where(user: contact, campaign_gid: campaign.gid).exists?
        assert_predicate CampaignReceipt.where(user: contact, step_gid: first_step_gid), :exists?
      end

      test "it only removes the users whose segment stopped matching" do
        campaign = create_test_campaign {
          default wait: 0
          user_type "Contact"
          halt true
          step :one, segment: ->(u) { u.traits["foo"] == "bar" }
          step :two, wait: 1.day
        }
        halting = contacts(:one)
        staying = contacts(:two)
        staying.update_attribute(:traits, {foo: "bar"})

        campaign.add(halting, send_now: false)
        campaign.add(staying, send_now: false)

        run_once

        refute CampaignMembership.where(user: halting, campaign_gid: campaign.gid).exists?
        membership = CampaignMembership.where(user: staying, campaign_gid: campaign.gid).first
        assert_equal campaign.steps.second.gid, membership.step_gid
      end
    end
  end
end
