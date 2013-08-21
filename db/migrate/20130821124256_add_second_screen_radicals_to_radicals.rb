class AddSecondScreenRadicalsToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :second_screen_radicals, :integer, :array => true, :default => []
  end
end
