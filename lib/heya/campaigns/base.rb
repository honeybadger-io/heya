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

      def add(user, restart: false, concurrent: false)
        restart && CampaignReceipt
          .where(user: user, step_gid: steps.map(&:gid))
          .delete_all
        CampaignMembership.where(user: user, campaign_gid: gid, concurrent: concurrent).first_or_create!
      end

      def remove(user)
        CampaignMembership.where(user: user, campaign_gid: gid).delete_all
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

        def step(name, **props)
          options = props.select { |k, _| __defaults.key?(k) }
          options[:properties] = props.reject { |k, _| __defaults.key?(k) }.stringify_keys
          options[:id] = "#{self.name}/#{name}"
          options[:name] = name.to_s
          options[:position] = steps.size
          options[:campaign] = instance

          step = Step.new(__defaults.merge(options))
          method_name = :"#{step.name.underscore}"
          raise "Invalid step name: #{step.name}\n  Step names must not conflict with method names on Heya::Campaigns::Base" if respond_to?(method_name)

          define_singleton_method method_name do |user|
            step.action.call(step: step, user: user)
          end
          steps << step

          step
        end
      end
    end
  end
end
