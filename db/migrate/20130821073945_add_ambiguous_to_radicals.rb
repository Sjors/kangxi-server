class AddAmbiguousToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :ambiguous, :boolean, :default => false
  end
end
