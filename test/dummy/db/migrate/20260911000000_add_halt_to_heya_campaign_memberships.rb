class AddHaltToHeyaCampaignMemberships < ActiveRecord::Migration[7.0]
  def change
    add_column :heya_campaign_memberships, :halt, :boolean, null: false, default: false
  end
end
