# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require "pathname"
TMP_PATH = Pathname(File.expand_path("../../tmp", __FILE__))
TMP_PATH.mkdir unless TMP_PATH.exist?

require "simplecov"
SimpleCov.start

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths)
  # Rails 7.1+
  ActiveSupport::TestCase.fixture_paths << (fixture_path = File.expand_path("fixtures", __dir__))
  ActionDispatch::IntegrationTest.fixture_paths += ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = fixture_path + "/files"
elsif ActiveSupport::TestCase.respond_to?(:fixture_path=)
  # Rails < 7.1
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
end

ActiveSupport::TestCase.fixtures :all

require "minitest/mock"

# For generator tests
if ActionMailer::Base.respond_to?(:preview_paths)
  # Rails 7.1+
  ActionMailer::Base.preview_paths << Rails.root.join("test/mailers/previews")
else
  # Rails < 7.1
  ActionMailer::Base.preview_path = Rails.root.join("test/mailers/previews")
end

class NullMail
  def self.deliver_later
  end
end

class NullAction
  def initialize(step:, user:)
    # noop
  end

  def deliver_later
    true
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
  def teardown
    Timecop.return
  end

  def create_test_campaign(name: "TestCampaign", parent: Heya::Campaigns::Base, action: NullAction, &block)
    klass = Class.new(parent) {
      class << self
        attr_accessor :name
      end
    }
    klass.name = name
    klass.default(action: action)
    klass.instance_exec(&block)
    Object.send(:remove_const, klass.name) if Object.const_defined?(klass.name.to_sym)
    Object.send(:const_set, klass.name.to_sym, klass)
    klass
  end

  def create_test_step(**params)
    create_test_campaign {
      step(:test, **params)
    }.steps.first
  end
end
