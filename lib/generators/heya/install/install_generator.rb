# frozen_string_literal: true

class Heya::InstallGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path("templates", __dir__)

  def copy_migrations
    migration_template "migration.rb", "db/migrate/create_heya_tables.rb"
  end

  def copy_initializer_file
    copy_file "initializer.rb", "config/initializers/heya.rb"
  end

  def copy_application_campaign_template
    template "application_campaign.rb", "app/campaigns/application_campaign.rb"
  end

  def self.next_migration_number(dirname)
    next_migration_number = current_migration_number(dirname) + 1
    ActiveRecord::Migration.next_migration_number(next_migration_number)
  end
end
