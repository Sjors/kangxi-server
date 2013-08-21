class AddTertiaryRadicalsToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :tertiary_radicals, :integer, :array => true, :default => []
  end
end
