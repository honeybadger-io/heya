class CreateHeyaMessageReceipts < ActiveRecord::Migration[5.2]
  def change
    create_table :heya_message_receipts do |t|
      t.references :contact, null: false, polymorphic: true, index: true

      t.string :message_gid, null: false

      t.datetime :sent_at

      t.timestamps
    end

    add_index :heya_message_receipts, [:contact_id, :message_gid], unique: true
  end
end
