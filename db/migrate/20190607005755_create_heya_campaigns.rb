class CreateHeyaCampaigns < ActiveRecord::Migration[5.2]
  def change
    create_table :heya_campaigns do |t|
      t.string :name
      t.integer :position, null: false

      t.timestamps
    end
  end
end
