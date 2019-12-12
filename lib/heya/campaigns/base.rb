require "ostruct"

module Heya
  module Campaigns
    # {Campaigns::Base} provides a Ruby DSL for building campaign sequences.
    # Multiple actions are supported; the default is email.
    class Base
      class << self
        class_attribute :__defaults, :__segment, :__contact_type

        self.__defaults = {
          action: Actions::Email,
          segment: -> { all },
          wait: 2.days,
        }.freeze

        self.__segment = -> { all }
        self.__contact_type = "User"

        def campaign
          @campaign ||= ::Heya::Campaign.where(name: name).first_or_create!.tap do |campaign|
            steps.each.with_index do |name_opts, i|
              name, opts = name_opts
              message = ::Heya::Message.where(campaign: campaign, name: name).first_or_create! { |message|
                message.position = i
                message.wait = opts.wait
              }
              message.update_attributes(position: i, wait: opts.wait)
              messages << message
            end
          end
        end
        alias load_model campaign

        def messages
          @messages ||= []
        end

        def steps
          @steps ||= {}
        end

        def default(**props)
          self.__defaults = __defaults.merge(props).freeze
        end

        def step(name, **props)
          options = props.select { |k, _| __defaults.key?(k) }
          options[:properties] = props.reject { |k, _| __defaults.key?(k) }.stringify_keys

          steps[name] = OpenStruct.new(__defaults.merge(options))
        end

        def segment(&block)
          if block_given?
            self.__segment = block
          end

          __segment
        end

        def contact_type(value = nil)
          if value.present?
            self.__contact_type = value.is_a?(String) ? value.to_s : value.name
          end

          __contact_type
        end

        delegate :add, :remove, to: :campaign
      end
    end
  end
end
