class AddNScreenToCharacters < ActiveRecord::Migration
  def change
    add_column :characters, :first_screen, :boolean, :default => false
    add_column :characters, :second_screen, :boolean, :default => false
    add_column :characters, :third_screen, :boolean, :default => false
  end
end
