require "heya/engine"
require "heya/actions"
require "heya/campaigns/base"
require "heya/campaigns/queries"
require "heya/campaigns/scheduler"
require "heya/campaigns/step"
require "heya/concerns/models/contact"

module Heya
  extend self

  attr_accessor :campaigns
  self.campaigns = []

  def register_campaign(subclass)
    campaigns << subclass
  end
end
