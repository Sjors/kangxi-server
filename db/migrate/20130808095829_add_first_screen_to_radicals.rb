class AddFirstScreenToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :first_screen, :boolean, :default => false
  end
end
