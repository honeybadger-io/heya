# frozen_string_literal: true

require "heya/version"
require "heya/active_record_extension"
require "heya/engine"
require "heya/config"
require "heya/license"
require "heya/campaigns/action"
require "heya/campaigns/actions/email"
require "heya/campaigns/actions/block"
require "heya/campaigns/base"
require "heya/campaigns/queries"
require "heya/campaigns/scheduler"
require "heya/campaigns/step"
require "heya/campaigns/step_action_job"

module Heya
  extend self

  attr_accessor :campaigns
  self.campaigns = []

  def register_campaign(klass)
    campaigns.push(klass) unless campaigns.include?(klass)
  end

  def unregister_campaign(klass)
    campaigns.delete(klass)
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

  def verify_license!
    unless File.file?(config.license_file)
      puts(<<-NOTICE.strip_heredoc)
        This copy of Heya is licensed for non-commercial non-profit, or 30-day trial usage only.
        For a commercial use license, please visit https://www.heya.email
      NOTICE
      return
    end

    begin
      license = License.import(File.read(config.license_file))
    rescue License::ImportError
      warn(<<-NOTICE.strip_heredoc)
        Your Heya license is invalid.
        If you need support, please visit https://www.heya.email
      NOTICE
      return
    end

    if license.expired?
      warn(<<-NOTICE.strip_heredoc)
        Your Heya license has expired.
        To update your license, please visit https://www.heya.email
      NOTICE
      return
    end

    if (max_user_count = license.restrictions[:user_count]&.to_i)
      user_count = config.user_type.constantize.count
      if user_count > max_user_count
        warn(<<-NOTICE.strip_heredoc)
          Your app exceeds the number of users for your Heya license.
          To upgrade your license, please visit https://www.heya.email
        NOTICE
      end
      return # rubocop:disable Style/RedundantReturn
    end

    # Valid license
  end
end
