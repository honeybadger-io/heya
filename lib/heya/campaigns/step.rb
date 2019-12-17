require "ostruct"

module Heya
  module Campaigns
    class Step < OpenStruct
      include GlobalID::Identification

      def self.find(id)
        campaign_name, _step_name = id.to_s.split("/")
        campaign_name.constantize.steps.find { |s| s.id == id }
      end

      def gid
        to_gid(app: "heya").to_s
      end

      def process_action?(user)
        in_segments?(user,
          user.class.__heya_default_segment,
          campaign.segment,
          segment)
      end

      private

      def in_segments?(user, *segments)
        return false if segments.any? { |s| !in_segment?(user, s) }
        true
      end

      def in_segment?(user, segment)
        return true if segment.nil?
        segment.call(user)
      end
    end
  end
end
