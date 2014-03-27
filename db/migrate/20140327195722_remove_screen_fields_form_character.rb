class RemoveScreenFieldsFormCharacter < ActiveRecord::Migration
  def change
    remove_column :characters, :first_screen
    remove_column :characters, :second_screen
    remove_column :characters, :third_screen
    remove_column :characters, :fourth_screen
  end
end
