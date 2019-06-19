module Heya
  module Campaigns
    # Campaigns::Base provides a Ruby DSL for building campaign sequences.
    # Multiple actions are supported; the default is email.
    class Base
      class << self
        def defaults
          @defaults ||= {
            contact_class: "User",
            action: Actions::Email,
            segment: -> { all },
            wait: 2.days,
          }
        end

        def campaign
          @campaign ||= ::Heya::Campaign.where(name: name).first_or_create!.tap(&:readonly!)
        end

        def messages
          @messages ||= []
        end

        def default(**opts)
          defaults.merge!(opts)
        end

        def step(name, **props)
          message = ::Heya::Message.where(campaign: campaign, name: name).first_or_create!
          message.properties = defaults.merge(props)
          message.readonly!
          messages << message
        end

        delegate :add, :add!, :remove, to: :campaign
      end
    end
  end
end
