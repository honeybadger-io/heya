class CreateHeyaCampaignMemberships < ActiveRecord::Migration[5.2]
  def change
    create_table :heya_campaign_memberships do |t|
      t.references :user, null: false, polymorphic: true, index: false

      t.string :campaign_gid, null: false

      t.datetime :last_sent_at, null: false

      t.timestamps
    end

    add_index :heya_campaign_memberships, [:user_type, :user_id, :campaign_gid], unique: true, name: :user_campaign_idx
  end
end
