class AddSecondScreenFrequencyToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :second_screen_frequency, :integer, :default => 0
  end
end
