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
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end

require "minitest/mock"

# For generator tests
Rails.application.config.action_mailer.preview_path = Rails.root.join("test/mailers/previews")

class NullMail
  def self.deliver_later
  end
end

class NullAction
  def initialize(step:, user:)
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
      step :test, **params
    }.steps.first
  end

  def generate_license(starts_at: Date.today, expires_at: 1.year.from_now.to_date, name: "Name", company: "Company", email: "user@example.com", user_count: nil)
    original_key = Heya::License.encryption_key

    Heya::License.encryption_key = File.read(File.expand_path("../fixtures/license/license_key", __FILE__))

    license = Heya::License.new

    license.licensee = {
      "Name" => name,
      "Company" => company,
      "Email" => email
    }

    license.starts_at = starts_at
    license.expires_at = expires_at

    license.restrictions = {user_count: user_count}

    license.export
  ensure
    Heya::License.encryption_key = original_key
  end

  def mock_license_key
    original_key = Heya::License.encryption_key
    Heya::License.encryption_key = File.read(File.expand_path("../fixtures/license/license_key.pub", __FILE__))
    yield
  ensure
    Heya::License.encryption_key = original_key
  end
end
