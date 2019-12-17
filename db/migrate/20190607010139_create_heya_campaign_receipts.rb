class CreateHeyaCampaignReceipts < ActiveRecord::Migration[5.2]
  def change
    create_table :heya_campaign_receipts do |t|
      t.references :contact, null: false, polymorphic: true, index: true

      t.string :step_gid, null: false

      t.datetime :sent_at

      t.timestamps
    end

    add_index :heya_campaign_receipts, [:contact_id, :step_gid], unique: true
  end
end
