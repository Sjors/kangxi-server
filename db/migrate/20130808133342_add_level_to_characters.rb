class AddLevelToCharacters < ActiveRecord::Migration
  def change
    add_column :characters, :level, :integer
    
    Character.all.each do |c|
      c.update level: 1
    end
  end
end
