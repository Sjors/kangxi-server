class CreateWords < ActiveRecord::Migration
  def change
    create_table :words do |t|
      t.string :simplified
      t.string :english, :array => true, :default => []

      t.timestamps
    end
  end
end
