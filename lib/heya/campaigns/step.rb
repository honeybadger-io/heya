# frozen_string_literal: true

require "ostruct"

module Heya
  module Campaigns
    class Step < OpenStruct
      include GlobalID::Identification

      def self.find(id)
        campaign_name, _step_name = id.to_s.split("/")
        campaign_name.constantize.steps.find { |s| s.id == id }
      end

      def initialize(id:, name:, campaign:, position:, action:, wait:, segment:, queue:, params: {})
        super
        if action.respond_to?(:validate_step)
          action.validate_step(self)
        end
      end

      def gid
        to_gid(app: "heya").to_s
      end

      def in_segment?(user)
        Heya.in_segments?(user, *campaign.__segments, segment)
      end

      def campaign_name
        @campaign_name ||= campaign.name
      end
    end
  end
end
