module Heya
  module Campaigns
    # {Campaigns::Base} provides a Ruby DSL for building campaign sequences.
    # Multiple actions are supported; the default is email.
    class Base
      include Singleton
      include GlobalID::Identification

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
        return false unless Heya.in_segments?(user, user.class.__heya_default_segment, *__segments)

        restart && CampaignReceipt
          .where(user: user, step_gid: steps.map(&:gid))
          .delete_all

        CampaignMembership.where(user: user, campaign_gid: gid, concurrent: concurrent).first_or_create!

        if send_now && (step = steps.first) && step.wait <= 0
          Scheduler.process(self, step, user)
        end

        true
      end

      def remove(user)
        CampaignMembership.where(user: user, campaign_gid: gid).delete_all
        true
      end

      def users
        base_class = user_class.base_class
        user_class
          .joins(
            sanitize_sql_array([
              "inner join heya_campaign_memberships on heya_campaign_memberships.user_type = ? and heya_campaign_memberships.user_id = #{base_class.table_name}.id and heya_campaign_memberships.campaign_gid = ?",
              base_class.name,
              gid,
            ])
          ).all
      end

      def user_class
        @user_class ||= self.class.user_type.constantize
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
        queue: "heya",
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

        def handle_exception(exception)
          raise exception
        end

        delegate :steps, :add, :remove, :users, :gid, :user_class, to: :instance

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
          attrs[:params] = opts.reject { |k, _| STEP_ATTRS.key?(k) }.stringify_keys
          attrs[:id] = "#{self.name}/#{name}"
          attrs[:name] = name.to_s
          attrs[:position] = steps.size
          attrs[:campaign] = instance

          step = Step.new(attrs)
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
