class CreateCharactersRadicals < ActiveRecord::Migration
  def change
    create_table :characters_radicals do |t|
      t.references :character, index: true
      t.references :radical, index: true

      t.timestamps
    end
  end
end
