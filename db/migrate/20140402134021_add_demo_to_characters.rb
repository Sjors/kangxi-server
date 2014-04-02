class AddDemoToCharacters < ActiveRecord::Migration
  def change
    add_column :characters, :demo, :boolean, default: false
    add_column :radicals, :demo, :boolean, default: false
    
  end
end
