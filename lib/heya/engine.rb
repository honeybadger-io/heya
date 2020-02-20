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
  end
end
