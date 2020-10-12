# frozen_string_literal: true

require "active_support/descendants_tracker"
require "active_support/rescuable"

module Heya
  module Campaigns
    # {Campaigns::Base} provides a Ruby DSL for building campaign sequences.
    # Multiple actions are supported; the default is email.
    class Base
      extend ActiveSupport::DescendantsTracker

      include Singleton
      include GlobalID::Identification
      include ActiveSupport::Rescuable

      def initialize
        self.steps = []
      end

      delegate :name, :__segments, to: :class
      alias id name

      # Returns String GlobalID.
      def gid
        to_gid(app: "heya").to_s
      end

      def add(user, restart: false, concurrent: false, send_now: true)
        return false unless Heya.in_segments?(user, *__segments)

        membership = CampaignMembership.where(user: user, campaign_gid: gid)
        if membership.exists?
          return false unless restart
          membership.delete_all
        end

        if restart
          CampaignReceipt
            .where(user: user, step_gid: steps.map(&:gid))
            .delete_all
        end

        if (step = steps.first)
          membership.create! do |m|
            m.concurrent = concurrent
            m.step_gid = step.gid
          end

          if send_now && step.wait == 0
            Scheduler.new.run(user: user)
          end
        end

        true
      end

      def remove(user)
        CampaignMembership.where(user: user, campaign_gid: gid).delete_all
        true
      end

      def user_class
        @user_class ||= self.class.user_type.constantize
      end

      def handle_exception(exception)
        rescue_with_handler(exception) || raise(exception)
      end

      attr_accessor :steps

      private

      delegate :sanitize_sql_array, to: ActiveRecord::Base

      class_attribute :__defaults, default: {}.freeze
      class_attribute :__segments, default: [].freeze
      class_attribute :__user_type, default: nil

      STEP_ATTRS = {
        action: Actions::Email,
        wait: 2.days,
        segment: nil,
        queue: "heya"
      }.freeze

      class << self
        def inherited(campaign)
          Heya.register_campaign(campaign)
          Heya.unregister_campaign(campaign.superclass)
          super
        end

        def find(_id)
          instance
        end

        delegate :steps, :add, :remove, :gid, :user_class, :handle_exception, to: :instance

        def default(**params)
          self.__defaults = __defaults.merge(params).freeze
        end

        def user_type(value = nil)
          if value.present?
            self.__user_type = value.is_a?(String) ? value.to_s : value.name
          end

          __user_type || Heya.config.user_type
        end

        def segment(arg = nil, &block)
          if block_given?
            self.__segments = ([block] | __segments).freeze
          elsif arg
            self.__segments = ([arg] | __segments).freeze
          end
        end

        def step(name, **opts, &block)
          if block_given?
            opts[:block] ||= block
            opts[:action] ||= Actions::Block
          end

          opts =
            STEP_ATTRS
              .merge(Heya.config.campaigns.default_options)
              .merge(__defaults)
              .merge(opts)

          attrs = opts.select { |k, _| STEP_ATTRS.key?(k) }
          attrs[:id] = "#{self.name}/#{name}"
          attrs[:name] = name.to_s
          attrs[:campaign] = instance
          attrs[:position] = steps.size
          attrs[:params] = opts.reject { |k, _| STEP_ATTRS.key?(k) }.stringify_keys

          step = Step.new(**attrs)
          method_name = :"#{step.name.underscore}"
          raise "Invalid step name: #{step.name}\n  Step names must not conflict with method names on Heya::Campaigns::Base" if respond_to?(method_name)

          define_singleton_method method_name do |user|
            step.action.new(user: user, step: step).build
          end
          steps << step

          step
        end
      end
    end
  end
end
