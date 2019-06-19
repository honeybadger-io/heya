class CreateHeyaCampaignMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :heya_campaign_memberships do |t|
      t.belongs_to :campaign, null: false, foreign_key: {to_table: "heya_campaigns"}
      t.references :contact, null: false, polymorphic: true, index: true

      t.datetime :last_sent_at, null: false

      t.timestamps
    end

    add_index :heya_campaign_memberships, [:contact_id, :campaign_id], unique: true
  end
end
