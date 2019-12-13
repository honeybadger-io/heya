class CreateHeyaCampaignMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :heya_campaign_memberships do |t|
      t.references :contact, null: false, polymorphic: true, index: true

      t.string :campaign_gid, null: false

      t.datetime :last_sent_at, null: false

      t.timestamps
    end

    add_index :heya_campaign_memberships, [:contact_id, :campaign_gid], unique: true
  end
end
