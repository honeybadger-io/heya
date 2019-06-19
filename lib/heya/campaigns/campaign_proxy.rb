module Heya
  module Campaigns
    # {Campaigns::CampaignProxy} is the final representation of a campaign. It
    # can be derived from the Ruby DSL, or (eventually) the web UI. The
    # underlying data model is lazy-evaluated via a block, which allows the
    # campaign to be initialized before the database.
    #
    # @example
    #
    #   props = {
    #     contact_class: "User",
    #     action: Heya::Actions::Email,
    #     segment: -> { all },
    #     wait: 2.days
    #   }
    #
    #   campaign = CampaignProxy.new {
    #     Campaign.where(name: 'MyCampaign').first_or_create!
    #   }
    #
    #   campaign << MessageProxy.new(**props) {
    #     Message.where(campaign_id: campaign.id, name: 'first').first_or_create!
    #   }
    class CampaignProxy
      def initialize(&block)
        @messages = []
        @block = block
      end

      delegate :id, :name, :add, :remove, to: :model
      delegate :<<, to: :messages

      attr_reader :messages

      def model
        @model ||= @block.call
      end

      def load_model
        messages.each(&:load_model)
        model
      end
    end
  end
end
