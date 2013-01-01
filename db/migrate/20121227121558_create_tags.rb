class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name
      t.integer :subject_id
      t.integer :value_id

      t.timestamps
    end
    add_index :tags, :name
    add_index :tags, :subject_id
    add_index :tags, :value_id
  end
end
