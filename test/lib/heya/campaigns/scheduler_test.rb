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

      def create_test_campaign(const = :TestCampaign, &block)
        Object.send(:remove_const, const) if Object.const_defined?(const)
        Object.send(:const_set, const, Class.new(Campaigns::Base, &block))
      end

      test "it loads campaign models before running" do
        mock = Minitest::Mock.new
        mock.expect(:call, nil)

        FirstCampaign.stub :load_model, mock do
          run_once
        end

        assert_mock mock
      end

      test "it processes campaign actions in order" do
        action = Minitest::Mock.new
        create_test_campaign do
          default action: action
          contact_type "Contact"
          step :one, wait: 5.days
          step :two, wait: 3.days
          step :three, wait: 2.days
        end
        contact = contacts(:one)
        TestCampaign.add(contact)

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(6.days.from_now)
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.first,
        }])
        run_twice
        assert_mock action

        Timecop.travel(2.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.second,
        }])
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.third,
        }])
        run_twice
        assert_mock action
      end

      test "it skips actions that don't match segments" do
        action = Minitest::Mock.new
        create_test_campaign do
          default wait: 0, action: action
          contact_type "Contact"
          step :one, segment: -> { where(traits: {foo: "bar"}) }
        end
        contact = contacts(:one)
        TestCampaign.add(contact)

        run_twice
        assert_mock action
      end

      test "it processes actions that match segments" do
        action = Minitest::Mock.new
        create_test_campaign do
          default wait: 0, action: action
          contact_type "Contact"
          step :one, segment: -> { where(traits: {foo: "bar"}) }
        end
        contact = contacts(:one)
        contact.update_attribute(:traits, {foo: "bar"})
        TestCampaign.add(contact)

        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.first,
        }])

        run_twice
        assert_mock action
      end

      test "it waits for segments to match" do
        action = Minitest::Mock.new
        create_test_campaign do
          default action: action
          contact_type "Contact"
          step :one, wait: 0
          step :two, wait: 2.days, segment: -> { where(traits: {foo: "bar"}) }
          step :three, wait: 1.day, segment: -> { where(traits: {bar: "baz"}) }
        end
        contact = contacts(:one)
        contact.update_attribute(:traits, {bar: "baz"})
        TestCampaign.add(contact)

        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.first,
        }])
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.third,
        }])
        run_once
        assert_mock action
      end

      test "it skips actions that don't match default segments" do
        action = Minitest::Mock.new
        class TestContact < Contact
          default_segment { where(traits: {foo: "bar"}) }
        end
        create_test_campaign do
          default wait: 0, action: action
          contact_type TestContact
          step :one
        end
        contact = contacts(:one).becomes(TestContact)
        TestCampaign.add(contact)

        run_once
        assert_mock action
      end

      test "it processes actions that match default segments" do
        action = Minitest::Mock.new
        class TestContact < Contact
          default_segment { where(traits: {foo: "bar"}) }
        end
        create_test_campaign do
          default wait: 0, action: action
          contact_type TestContact
          step :one
        end
        contact = contacts(:one).becomes(TestContact)
        contact.update_attribute(:traits, {foo: "bar"})
        TestCampaign.add(contact)

        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.first,
        }])

        run_once
        assert_mock action
      end

      test "it skips actions that don't match campaign segment" do
        action = Minitest::Mock.new
        create_test_campaign do
          default wait: 0, action: action
          contact_type "Contact"
          segment { where("traits->>? = ?", "foo", "foo") }
          step :one
        end
        contact = contacts(:one)
        TestCampaign.add(contact)

        run_once

        assert_mock action
      end

      test "it processes actions that match campaign segment" do
        action = Minitest::Mock.new
        create_test_campaign do
          default wait: 0, action: action
          contact_type "Contact"
          segment { where("traits->>? = ?", "foo", "foo") }
          step :one
        end
        contact = contacts(:one)
        contact.update_attribute(:traits, {foo: "foo"})
        TestCampaign.add(contact)

        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.first,
        }])

        run_once

        assert_mock action
      end

      test "it removes contacts from campaign at end" do
        create_test_campaign do
          default wait: 0
          contact_type "Contact"
          step :one
          step :two
          step :three
        end
        contact = contacts(:one)
        TestCampaign.add(contact)

        assert CampaignMembership.where(campaign: TestCampaign.model, contact: contact).exists?

        run_once

        refute CampaignMembership.where(campaign: TestCampaign.model, contact: contact).exists?
      end

      test "it processes campaign actions concurrently" do
        action = Minitest::Mock.new
        create_test_campaign do
          default wait: 0, action: action
          contact_type "Contact"
          step :one
        end
        contact = contacts(:one)
        TestCampaign.add(contact)

        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign.messages.first,
        }])

        20.times.map {
          Thread.new {
            run_once
          }
        }.each(&:join)

        assert_mock action
      end

      test "it processes multiple campaign actions in order" do
        action = Minitest::Mock.new
        create_test_campaign(:TestCampaign1) do
          default action: action
          contact_type "Contact"
          step :one, wait: 5.days
        end
        create_test_campaign(:TestCampaign2) do
          default action: action
          contact_type "Contact"
          step :one, wait: 3.days
        end
        create_test_campaign(:TestCampaign3) do
          default action: action
          contact_type "Contact"
          step :one, wait: 2.days
        end
        contact = contacts(:one)
        TestCampaign1.add(contact)
        TestCampaign2.add(contact)
        TestCampaign3.add(contact)

        Heya.configure do |config|
          config.priority = [
            TestCampaign1,
            TestCampaign2,
            TestCampaign3,
          ]
        end

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(6.days.from_now)
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign1.messages.first,
        }])
        run_twice
        assert_mock action

        Timecop.travel(2.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign2.messages.first,
        }])
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        run_twice
        assert_mock action

        Timecop.travel(1.days.from_now)
        action.expect(:call, nil, [{
          contact: contact,
          message: TestCampaign3.messages.first,
        }])
        run_twice
        assert_mock action
      end
    end
  end
end
