module Heya
  class Engine < ::Rails::Engine
    isolate_namespace Heya

    config.to_prepare do
      Dir.glob(Rails.root + "app/campaigns/*.rb").each do |c|
        require_dependency(c)
      end
    end
  end
end
