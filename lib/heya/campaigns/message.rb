require "ostruct"

module Heya
  module Campaigns
    class Message < OpenStruct
      include GlobalID::Identification

      def self.find(id)
        campaign_name, _message_name = id.to_s.split("/")
        campaign_name.constantize.messages.find { |m| m.id == id }
      end

      def gid
        to_gid(app: "heya").to_s
      end
    end
  end
end
