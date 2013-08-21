class AddSecondaryRadicalsToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :secondary_radicals, :integer, :array => true, :default => []
  end
end
