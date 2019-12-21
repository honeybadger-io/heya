class Heya::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  def copy_migrations
    rake "heya:install:migrations"
  end

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/heya.rb"
  end
end
