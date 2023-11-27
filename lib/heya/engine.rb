# frozen_string_literal: true

module Heya
  class Engine < ::Rails::Engine
    isolate_namespace Heya

    initializer "heya.reload_campaigns" do |app|
      app.reloader.to_run do
        Heya.campaigns.clear
      end
    end

    config.to_prepare do
      # This runs the first time *before* Rails is initialized. Because
      # campaigns depend on Rails initialization, we use the `after_initialize`
      # hook when Rails first starts up, and then `to_prepare` when reloading
      # in development. See https://github.com/honeybadger-io/heya/issues/211
      if ::Rails.application.initialized?
        Dir.glob(Rails.root + "app/campaigns/*.rb").each do |c|
          require_dependency(c)
        end
      end
    end

    config.after_initialize do
      Dir.glob(Rails.root + "app/campaigns/*.rb").each do |c|
        require_dependency(c)
      end
    end
  end
end
