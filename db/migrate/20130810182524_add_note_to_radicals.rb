class AddNoteToRadicals < ActiveRecord::Migration
  def change
    add_column :radicals, :note, :string
  end
end
