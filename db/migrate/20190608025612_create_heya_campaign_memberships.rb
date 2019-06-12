class CreateHeyaCampaignMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :heya_campaign_memberships do |t|
      t.belongs_to :contact, null: false, foreign_key: {to_table: "heya_contacts"}
      t.belongs_to :campaign, null: false, foreign_key: {to_table: "heya_campaigns"}

      t.datetime :last_sent_at, null: false

      t.timestamps
    end

    add_index :heya_campaign_memberships, [:contact_id, :campaign_id], unique: true
  end
end
