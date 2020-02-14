module Heya
  module Campaigns
    # {Campaigns::Base} provides a Ruby DSL for building campaign sequences.
    # Multiple actions are supported; the default is email.
    class Base
      include Singleton
      include GlobalID::Identification

      def self.inherited(campaign)
        Heya.register_campaign(campaign)
        super
      end

      def self.find(_id)
        instance
      end

      def initialize
        self.steps = []
      end

      delegate :name, :segment, to: :class
      alias id name

      # Returns String GlobalID.
      def gid
        to_gid(app: "heya").to_s
      end

      def add(user, restart: false, concurrent: false, send_now: true)
        return false unless Heya.in_segments?(user, user.class.__heya_default_segment, segment)

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

      class << self
        private

        class_attribute :__defaults, :__segment, :__user_type

        self.__defaults = {
          action: Actions::Email,
          wait: 2.days,
          segment: nil,
        }.freeze

        self.__segment = nil
        self.__user_type = nil

        public

        delegate :steps, :add, :remove, :users, :gid, :user_class, to: :instance

        def user_type(value = nil)
          if value.present?
            self.__user_type = value.is_a?(String) ? value.to_s : value.name
          end

          __user_type || Heya.config.user_type
        end

        def default(**props)
          self.__defaults = __defaults.merge(props).freeze
        end

        def segment(&block)
          if block_given?
            self.__segment = block
          end

          __segment
        end

        def step(name, **props, &block)
          options = props.select { |k, _| __defaults.key?(k) }
          options[:properties] = props.reject { |k, _| __defaults.key?(k) }.stringify_keys
          options[:id] = "#{self.name}/#{name}"
          options[:name] = name.to_s
          options[:position] = steps.size
          options[:campaign] = instance
          options[:action] = Actions::Block.build(block) if block_given?

          step = Step.new(__defaults.merge(options))
          method_name = :"#{step.name.underscore}"
          raise "Invalid step name: #{step.name}\n  Step names must not conflict with method names on Heya::Campaigns::Base" if respond_to?(method_name)

          define_singleton_method method_name do |user|
            step.action.call(user: user, step: step)
          end
          steps << step

          step
        end
      end
    end
  end
end
