class AddSynonymsToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :synonyms, :integer, :array => true, :default => []
  end
end
