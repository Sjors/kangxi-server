class AddSecondScreenToRadical < ActiveRecord::Migration
  def change
    add_column :radicals, :second_screen, :boolean, :default => false
  end
end
