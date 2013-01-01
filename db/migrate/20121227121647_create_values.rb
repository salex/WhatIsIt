class CreateValues < ActiveRecord::Migration
  def change
    create_table :values do |t|
      t.string :name
      t.text :info

      t.timestamps
    end
    add_index :values, :name
  end
end
