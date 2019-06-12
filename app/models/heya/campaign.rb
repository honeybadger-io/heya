module Heya
  class Campaign < ApplicationRecord
    self.table_name = "heya_campaigns"

    has_many :messages
    has_many :campaign_memberships
    has_many :contacts, through: :campaign_memberships

    def add(contact)
      campaign_memberships.where(contact: contact).first_or_create!
    end

    def remove(contact)
      campaign_memberships.where(contact: contact).destroy_all
    end
  end
end
