module Heya
  class Campaign < ApplicationRecord
    self.table_name = "heya_campaigns"

    has_many :messages
    has_many :memberships, class_name: "CampaignMembership"

    delegate :sanitize_sql_array, to: ActiveRecord::Base

    def contacts(class_name)
      contact_relation = class_name.constantize
      contact_relation
        .joins(
          sanitize_sql_array([
            "inner join heya_campaign_memberships on heya_campaign_memberships.contact_type = ? and heya_campaign_memberships.contact_id = #{contact_relation.table_name}.id and heya_campaign_memberships.campaign_id = ?",
            class_name,
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
  end
end
