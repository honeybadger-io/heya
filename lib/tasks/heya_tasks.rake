namespace :heya do
  desc "Send campaign emails"
  task scheduler: :environment do
    Heya::Campaigns::Scheduler.new.run
  end
end
