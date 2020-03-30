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
      Dir.glob(Rails.root + "app/campaigns/*.rb").each do |c|
        require_dependency(c)
      end
    end

    config.after_initialize do
      license_key = File.expand_path("../../../license_key.pub", __FILE__)
      License.encryption_key = File.read(license_key) if File.file?(license_key)

      Heya.configure do |config|
        config.license_file ||= Rails.root.join("config/Heya.heya-license")
      end

      Heya.verify_license!
    end
  end
end
