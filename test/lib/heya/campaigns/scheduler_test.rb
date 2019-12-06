require "test_helper"

module Heya
  module Campaigns
    class SchedulerTest < ActiveSupport::TestCase
      def run_once
        Scheduler.new.run
      end

      def run_twice
        2.times do
          run_once
        end
      end

      def create_test_campaign(&block)
        Object.send(:remove_const, :TestCampaign) if Object.const_defined?(:TestCampaign)
        Object.send(:const_set, :TestCampaign, Class.new(Campaigns::Base, &block))
      end

      test "it loads campaign models before running" do
        mock = Minitest::Mock.new
        mock.expect(:call, nil)

        FirstCampaign.stub :load_model, mock do
          run_once
        end

        assert_mock mock
      end

      test "it processes campaign actions on time" do
        # Setup
        action = Minitest::Mock.new

        create_test_campaign do
          default contact_class: "Contact"

          step :one, wait: 0, action: action
          step :two, wait: 2.days, action: action
          step :three, wait: 3.days, action: action
        end

        contact = contacts(:one)
        TestCampaign.add(contact)

        # First action expected immediately
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.first,
        }])

        run_twice

        assert_mock action

        # Second action expected 2 days later
        Timecop.travel(2.days.from_now)

        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.second,
        }])

        run_twice

        assert_mock action

        # Nothing expected 2 days later
        Timecop.travel(2.days.from_now)

        run_twice

        assert_mock action

        # Third action expected one day later
        Timecop.travel(1.days.from_now)

        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.third,
        }])

        run_twice

        assert_mock action
      end

      test "it processes campaign actions in order" do
        # Setup
        action = Minitest::Mock.new

        create_test_campaign do
          default contact_class: "Contact"

          step :one, wait: 0, action: action
          step :two, wait: 2.days, action: action, segment: -> { where(traits: {foo: "bar"}) }
          step :three, wait: 3.days, action: action
        end

        contact = contacts(:one)
        TestCampaign.add(contact)

        # First action expected immediately
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.first,
        }])

        run_twice

        assert_mock action

        # Second action expected 2 days later
        Timecop.travel(2.days.from_now)

        # Nothing expected--segment doesn't match
        run_once

        assert_mock action

        # Third action expected one day later
        Timecop.travel(1.days.from_now)

        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.third,
        }])

        run_twice

        assert_mock action

        Timecop.travel(2.days.from_now)

        contact.update_attribute(:traits, {foo: "bar"})

        # Nothing expected--campaign has moved on.
        run_once

        assert_mock action
      end

      test "it processes actions that match segments" do
        # Setup
        action = Minitest::Mock.new

        create_test_campaign do
          default contact_class: "Contact"

          step :one, wait: 0, action: action
          step :two, wait: 0, action: action, segment: -> { where(traits: {foo: "bar"}) }
          step :three, wait: 0, action: action, segment: -> { where(traits: {bar: "baz"}) }
        end

        contact = contacts(:one)
        TestCampaign.add(contact)

        # First action expected when segment matches
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.first,
        }])

        run_once

        assert_mock action

        # No action expected until segment matches
        run_once

        assert_mock action

        # Third action expected when segment matches
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.third,
        }])

        contact.update_attribute(:traits, {bar: "baz"})

        run_once

        assert_mock action
      end

      test "it processes actions that match default segments" do
        # Setup
        action = Minitest::Mock.new

        class TestContact < Contact
          default_segment { where(traits: {foo: "bar"}) }
        end

        create_test_campaign do
          default contact_class: TestContact

          step :one, wait: 0, action: action
        end

        contact = contacts(:one).becomes(TestContact)
        TestCampaign.add(contact)

        # Nothing expected until segment matches
        run_once

        assert_mock action

        contact.update_attribute(:traits, {foo: "bar"})

        # First action expected once default segment matches
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.first,
        }])

        run_once

        assert_mock action
      end

      test "it removes contacts from campaign at end" do
        # Setup
        action = Minitest::Mock.new

        create_test_campaign do
          default contact_class: "Contact"

          step :one, wait: 0, action: action
          # step two will be skipped due to conditions
          step :two, wait: 0, action: action, segment: -> { where(traits: {foo: "bar"}) }
          step :three, wait: 0, action: action
        end

        contact = contacts(:one)
        TestCampaign.add(contact)

        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.first,
        }])

        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.third,
        }])

        assert CampaignMembership.where(campaign: TestCampaign.campaign, contact: contact).exists?

        run_once

        assert_mock action

        refute CampaignMembership.where(campaign: TestCampaign.campaign, contact: contact).exists?
      end
    end
  end
end
