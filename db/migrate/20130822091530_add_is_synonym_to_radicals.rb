class AddIsSynonymToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :is_synonym, :boolean, :default => false
  end
end
