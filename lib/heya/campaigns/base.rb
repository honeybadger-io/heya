require "ostruct"

module Heya
  module Campaigns
    # {Campaigns::Base} provides a Ruby DSL for building campaign sequences.
    # Multiple actions are supported; the default is email.
    class Base
      class << self
        class_attribute :defaults, :__segment

        self.defaults = {
          contact_class: "User",
          action: Actions::Email,
          segment: -> { all },
          wait: 2.days,
        }.freeze

        self.__segment = -> { all }

        def campaign
          @campaign ||= ::Heya::Campaign.where(name: name).first_or_create!.tap do |campaign|
            steps.each.with_index do |name_opts, i|
              name, opts = name_opts
              message = ::Heya::Message.where(campaign: campaign, name: name).first_or_create! do |message|
                message.position = i
              end
              message.update_attribute(:position, i)
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
          self.defaults = defaults.merge(props).freeze
        end

        def step(name, **props)
          options = props.select { |k, _| defaults.key?(k) }
          options[:properties] = props.reject { |k, _| defaults.key?(k) }.stringify_keys

          steps[name] = OpenStruct.new(defaults.merge(options))
        end

        def segment(&block)
          if block_given?
            self.__segment = block
          end

          self.__segment
        end

        delegate :add, :remove, to: :campaign
      end
    end
  end
end
