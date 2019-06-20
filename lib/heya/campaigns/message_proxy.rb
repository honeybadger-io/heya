module Heya
  module Campaigns
    # {Campaigns::MessageProxy} is the final representation of a message. It
    # can be derived from the Ruby DSL, or (eventually) the web UI. The
    # underlying data model is lazy-evaluated via a block, which allows the
    # message to be initialized before the database.
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
    #   MessageProxy.new(**props) {
    #     Message.where(campaign_id: 1, name: 'first').first_or_create!
    #   }
    class MessageProxy
      def initialize(contact_class:, action:, segment:, wait:, &block)
        @block = block
        @contact_class = contact_class.constantize
        @action = action
        @segment = @contact_class.instance_exec(&segment)
        @wait = wait
      end

      attr_reader :contact_class, :action, :segment, :wait

      delegate :id, :name, :properties, to: :model

      def model
        @model ||= @block.call
      end
      alias load_model model
    end
  end
end
