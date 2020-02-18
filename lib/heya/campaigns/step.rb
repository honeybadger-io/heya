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

      def in_segment?(user)
        Heya.in_segments?(user, user.class.__heya_default_segment, *campaign.__segments, segment)
      end
    end
  end
end
