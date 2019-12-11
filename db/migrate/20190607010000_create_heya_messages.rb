class CreateHeyaMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :heya_messages do |t|
      t.belongs_to :campaign, optional: true, foreign_key: {to_table: "heya_campaigns"}
      t.string :name
      t.integer :position

      t.timestamps
    end
    add_index :heya_messages, [:campaign_id, :position]
  end
end
