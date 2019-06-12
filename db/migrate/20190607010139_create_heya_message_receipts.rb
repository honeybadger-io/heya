class CreateHeyaMessageReceipts < ActiveRecord::Migration[5.2]
  def change
    create_table :heya_message_receipts do |t|
      t.belongs_to :message, null: false, foreign_key: {to_table: "heya_messages"}
      t.belongs_to :contact, null: false, foreign_key: {to_table: "heya_contacts"}

      t.datetime :sent_at, null: false

      t.timestamps
    end

    add_index :heya_message_receipts, [:message_id, :contact_id], unique: true
  end
end
