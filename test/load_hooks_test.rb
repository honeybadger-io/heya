# frozen_string_literal: true

require "test_helper"
require "open3"

class Heya::LoadHooksTest < ActiveSupport::TestCase
  # Referencing a framework base class while the gem is required runs its
  # on_load hooks before the app's config/initializers, so settings made there
  # are silently ignored. The test helper has already booted Rails, so check
  # in a fresh process.
  test "requiring heya does not load framework base classes" do
    script = <<~RUBY
      require "bundler/setup"
      require "rails/all"
      loaded = []
      %i[active_record active_job action_mailer].each do |hook|
        ActiveSupport.on_load(hook) { loaded << hook }
      end
      require "heya"
      print loaded.uniq.join(",")
    RUBY

    lib = File.expand_path("../lib", __dir__)
    output, status = Open3.capture2e(RbConfig.ruby, "-I", lib, "-e", script)

    assert status.success?, output
    assert_equal "", output, "Framework base classes were loaded by `require \"heya\"`"
  end

  test "eager loading the app loads StepActionJob" do
    script = <<~RUBY
      require #{File.expand_path("dummy/config/environment", __dir__).inspect}
      print Heya::Campaigns.autoload?(:StepActionJob).inspect
    RUBY

    env = {"RAILS_ENV" => "production", "SECRET_KEY_BASE" => "test"}
    output, status = Open3.capture2e(env, RbConfig.ruby, "-e", script)

    assert status.success?, output
    assert_equal "nil", output
  end
end
