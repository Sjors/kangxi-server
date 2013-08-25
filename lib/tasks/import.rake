require 'csv'
require 'open-uri'
namespace :import do 
  desc "Import HSK characters level 2 through 6"
  task :hsk2_6 => :environment do 
    # csv_text = File.read('hsk6.csv')
    csv_text = open("lib/assets/HSK_Level_6.csv") { |f| f.read }
    csv = CSV.parse(csv_text, :headers => true)
    csv_ordered = csv.to_a[2..-11].sort{|a,b| a[0].to_i <=> b[0].to_i} #  Skip header and empty bottom rows, order by level
    csv_ordered.each do |row| #
      if row[0].to_i > 1 # Level 2 and above
        row[1].each_char do |character|
          unless Character.find_by simplified: character
            Character.create(simplified: character, level: row[0].to_i)
          end
        end
      end
    end
  end
  
  desc "Remove current words"
  task :delete_words => :environment do
    Word.destroy_all
  end
  
  desc "Import HSK words"
  task :hsk_words => :environment do
    csv_text = open("lib/assets/HSK_Level_6.csv") { |f| f.read }
    csv = CSV.parse(csv_text, :headers => true).to_a[2..-11]
    csv.each do |row|
      word = Word.find_or_create_by(simplified: row[1])
      word.simplified.split(//).each do |c|
        character = Character.find_by simplified: c
        if character
          word.characters << character
        end
      end
    end 
  end
  
  desc "Import more words for characters"
  task :extra_words => :environment do
    Character.all.order("id asc").each do |character|
      puts "#{ (character.id.to_f / Character.count.to_f * 100.0 ).round }%..." if character.id % 100 == 0
      Zidian.find(character.simplified).each do |entry|
        if character.words.count < 10 && entry.english.count > 0 && entry.simplified.split(//).count <= 4
          word = Word.find_or_create_by(simplified: entry.simplified)
          unless character.words.include?(word)
            character.words << word
          end
        end
      end
    end
  end
  
  desc "Add meanings to words"
  task :dictionary  => :environment do
    Word.all.order("id asc").each do |word|
      puts "#{ (word.id.to_f / Word.count.to_f * 100.0 ).round }%..." if word.id % 500 == 0
            
      Zidian.find(word.simplified).each do |entry|
        if entry.simplified == word.simplified && !entry.english.empty?
          word.update english: entry.english.slice(0,3).collect{|meaning| meaning.slice(0,25)}
        end
      end
    end
  end
end
