class AddDoNotConfuseToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :do_not_confuse, :integer, :array => true, :default => []
  end
end
