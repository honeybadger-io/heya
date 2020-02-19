# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require 'simplecov'
SimpleCov.start

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end

require "minitest/mock"

class NullMail
  def self.deliver_later
  end
end

module Heya::Campaigns
  class TestAction < Action
    class Message
      def initialize(mock, *args)
        @mock, @args = mock, args
      end

      def deliver
        @mock&.call(*@args)
      end
    end

    class_attribute :__mock

    def self.mock(mock)
      self.__mock = mock
      yield
    ensure
      self.__mock = nil
    end

    def build
      Message.new(__mock, user, step)
    end
  end
end

class ActiveSupport::TestCase
  def create_test_campaign(name: "TestCampaign", parent: Heya::Campaigns::Base, &block)
    klass = Class.new(parent) {
      class << self
        attr_accessor :name
      end
    }
    klass.name = name
    klass.instance_exec(&block)
    klass
  end
end
