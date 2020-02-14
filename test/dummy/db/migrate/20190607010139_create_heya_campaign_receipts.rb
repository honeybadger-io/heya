class CreateHeyaCampaignReceipts < ActiveRecord::Migration[5.2]
  def change
    create_table :heya_campaign_receipts do |t|
      t.references :user, null: false, polymorphic: true, index: false

      t.string :step_gid, null: false

      t.datetime :sent_at

      t.timestamps
    end

    add_index :heya_campaign_receipts, [:user_type, :user_id, :step_gid], unique: true, name: :user_step_idx
  end
end
