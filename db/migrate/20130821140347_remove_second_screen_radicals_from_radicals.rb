class RemoveSecondScreenRadicalsFromRadicals < ActiveRecord::Migration
  def up
    remove_column :radicals, :second_screen_radicals
  end
end
