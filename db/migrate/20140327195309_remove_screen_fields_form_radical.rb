class RemoveScreenFieldsFormRadical < ActiveRecord::Migration
  def up
    remove_column :radicals, :first_screen
    remove_column :radicals, :second_screen
    remove_column :radicals, :second_screen_frequency
    remove_column :radicals, :secondary_radicals
    remove_column :radicals, :tertiary_radicals
    remove_column :radicals, :third_screen
    remove_column :radicals, :third_screen_frequency
  end
end
