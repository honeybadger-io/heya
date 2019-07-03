module Heya
  class Campaign < ApplicationRecord
    self.table_name = "heya_campaigns"

    has_many :messages, dependent: :destroy
    has_many :memberships, class_name: "CampaignMembership", dependent: :destroy

    delegate :sanitize_sql_array, to: ActiveRecord::Base

    def contacts(class_name)
      klass = class_name.constantize
      base_klass = klass.base_class

      klass
        .joins(
          sanitize_sql_array([
            "inner join heya_campaign_memberships on heya_campaign_memberships.contact_type = ? and heya_campaign_memberships.contact_id = #{base_klass.table_name}.id and heya_campaign_memberships.campaign_id = ?",
            base_klass.name,
            id,
          ])
        ).all
    end

    def add(contact)
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
  end
end
