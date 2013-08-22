class AddFourthScreenToCharacters < ActiveRecord::Migration
  def change
    add_column :characters, :fourth_screen, :boolean, :default => false
  end
end
