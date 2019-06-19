module Heya
  module Campaigns
    # {Campaigns::Base} provides a Ruby DSL for building campaign sequences.
    # Multiple actions are supported; the default is email.
    class Base
      class << self
        class_attribute :defaults

        self.defaults = {
          contact_class: "User",
          action: Actions::Email,
          segment: -> { all },
          wait: 2.days,
        }.freeze

        def campaign
          @campaign ||= CampaignProxy.new {
            ::Heya::Campaign.where(name: name).first_or_create!.tap(&:readonly!)
          }
        end

        def default(**props)
          self.defaults = defaults.merge(props).freeze
        end

        def step(name, **props)
          proxy_props = props.select { |k, _| defaults.key?(k) }
          message_props = props.reject { |k, _| defaults.key?(k) }.stringify_keys

          campaign << MessageProxy.new(**defaults.merge(proxy_props)) {
            message = ::Heya::Message.where(campaign: campaign.model, name: name).first_or_create!
            message.properties = message_props
            message.readonly!
            message
          }
        end

        delegate :add, :remove, :messages, to: :campaign
      end
    end
  end
end
