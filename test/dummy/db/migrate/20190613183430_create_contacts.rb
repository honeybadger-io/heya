class CreateContacts < ActiveRecord::Migration[5.2]
  def change
    create_table :contacts do |t|
      t.string :email
      t.jsonb :traits

      t.timestamps
    end
  end
end
