class AddFrequencyToRadical < ActiveRecord::Migration
  def change
    add_column :radicals, :frequency, :integer, :default => 0
  end
end
