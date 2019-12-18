require "heya/engine"
require "heya/actions"
require "heya/campaigns/base"
require "heya/campaigns/queries"
require "heya/campaigns/scheduler"
require "heya/campaigns/step"
require "heya/concerns/models/user"

module Heya
  extend self

  attr_accessor :campaigns
  self.campaigns = []

  def register_campaign(subclass)
    campaigns << subclass
  end

  def in_segments?(user, *segments)
    return false if segments.any? { |s| !in_segment?(user, s) }
    true
  end

  def in_segment?(user, segment)
    return true if segment.nil?
    segment.call(user)
  end
end
