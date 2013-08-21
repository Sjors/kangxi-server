class AddThirdScreenToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :third_screen, :boolean, :default => false
    add_column :radicals, :third_screen_frequency, :integer, :default => 0
  end
end
