require "heya/engine"
require "heya/config"
require "heya/campaigns/actions"
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

  def configure
    yield(config) if block_given?
    config
  end

  def config
    @config ||= Config.new
  end

  def in_segments?(user, *segments)
    return false if segments.any? { |s| !in_segment?(user, s) }
    true
  end

  def in_segment?(user, segment)
    return true if segment.nil?
    return user.send(segment) if segment.is_a?(Symbol)
    segment.call(user)
  end
end
