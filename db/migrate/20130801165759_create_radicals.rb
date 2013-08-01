class CreateRadicals < ActiveRecord::Migration
  def change
    create_table :radicals do |t|
      t.integer :position
      t.string :simplified
      t.boolean :variant, :default => false

      t.timestamps
    end
  end
end
