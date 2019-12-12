require "heya/engine"
require "heya/actions"
require "heya/campaigns/base"
require "heya/campaigns/queries"
require "heya/campaigns/scheduler"
require "heya/concerns/models/contact"

module Heya
  extend self

  def configure
    yield(config)
    update
    config
  end

  def config
    @config ||= OpenStruct.new(
      priority: [],
    )
  end

  def update
    Campaigns::Base.subclasses.each(&:load_model)
    ActiveRecord::Base.transaction do
      Campaign.update_all(position: -1)
      config.priority.reverse_each.with_index do |campaign, index|
        campaign.model.update_attribute(:position, index)
      end
    end
  end
end
