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
        self.messages = []
      end

      def name
        self.class.name
      end
      alias id name

      # Returns String GlobalID.
      def gid
        to_gid(app: "heya").to_s
      end

      def add(contact, restart: false)
        restart && CampaignReceipt
          .where(contact: contact, message_gid: messages.map(&:gid))
          .delete_all
        CampaignMembership.where(contact: contact, campaign_gid: gid).first_or_create!
      end

      def remove(contact)
        CampaignMembership.where(contact: contact, campaign_gid: gid).delete_all
      end

      def contacts
        base_class = contact_class.base_class
        contact_class
          .joins(
            sanitize_sql_array([
              "inner join heya_campaign_memberships on heya_campaign_memberships.contact_type = ? and heya_campaign_memberships.contact_id = #{base_class.table_name}.id and heya_campaign_memberships.campaign_gid = ?",
              base_class.name,
              gid,
            ])
          ).all
      end

      def contact_class
        @contact_class ||= self.class.contact_type.constantize
      end

      attr_accessor :messages

      private

      delegate :sanitize_sql_array, to: ActiveRecord::Base

      class << self
        private

        class_attribute :__defaults, :__segment, :__contact_type

        self.__defaults = {
          action: Actions::Email,
          segment: -> { all },
          wait: 2.days,
        }.freeze

        self.__segment = -> { all }
        self.__contact_type = "User"

        public

        delegate :messages, :add, :remove, :contacts, :gid, :contact_class, to: :instance

        def contact_type(value = nil)
          if value.present?
            self.__contact_type = value.is_a?(String) ? value.to_s : value.name
          end

          __contact_type
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
          options[:name] = name
          options[:position] = messages.size
          options[:campaign] = instance

          messages << Message.new(__defaults.merge(options))
        end
      end
    end
  end
end
