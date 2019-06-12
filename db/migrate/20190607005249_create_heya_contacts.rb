class CreateHeyaContacts < ActiveRecord::Migration[5.2]
  def change
    create_table :heya_contacts do |t|
      # t.belongs_to :user, optional: true, foreign_key: true

      t.string :email

      t.datetime :last_contacted

      t.timestamps
    end
  end
end
