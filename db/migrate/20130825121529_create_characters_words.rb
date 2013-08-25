class CreateCharactersWords < ActiveRecord::Migration
  def change
    create_table :characters_words do |t|
      t.references :character, index: true
      t.references :word, index: true
    end
  end
end
