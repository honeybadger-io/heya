module Heya
  class Campaign < ApplicationRecord
    self.table_name = "heya_campaigns"

    has_many :messages, -> { order("position") }, dependent: :destroy
    has_many :memberships, class_name: "CampaignMembership", dependent: :destroy

    delegate :sanitize_sql_array, to: ActiveRecord::Base
    delegate :segment, :contact_type, to: :klass

    def contacts
      base_class = contact_class.base_class
      contact_class
        .joins(
          sanitize_sql_array([
            "inner join heya_campaign_memberships on heya_campaign_memberships.contact_type = ? and heya_campaign_memberships.contact_id = #{base_class.table_name}.id and heya_campaign_memberships.campaign_id = ?",
            base_class.name,
            id,
          ])
        ).all
    end

    def add(contact, restart: false)
      restart && MessageReceipt
        .where(message: Message.where(campaign: self))
        .delete_all
      memberships.where(contact: contact).first_or_create!
    end

    def remove(contact)
      memberships.where(contact: contact).destroy_all
    end

    def klass
      @klass ||= name.constantize
    end

    def ordered_messages
      klass.messages
    end

    def contact_class
      @contact_class ||= contact_type.constantize
    end
  end
end
