class AddRadicalsToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :radicals, :integer, :array => true, :default => []
  end
end
