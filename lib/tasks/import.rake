require 'csv'
require 'open-uri'
namespace :import do 
  task :words => [:delete_words, :zidian_for_all_characters] # :hsk_words] #, :extra_words]
  
  
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
    query = "DELETE FROM characters_words;"
    ActiveRecord::Base.connection.execute(query);
    
    query = "DELETE FROM words;"
    ActiveRecord::Base.connection.execute(query);
  end
  
  # desc "Import HSK words"
  # task :hsk_words => :environment do
  #   csv_text = open("lib/assets/HSK_Level_6.csv") { |f| f.read }
  #   csv = CSV.parse(csv_text, :headers => true).to_a[2..-11]
  #   last_interval = Time.now
  #   csv.each do |row|
  #     
  #     if Time.now - last_interval > 60
  #       puts "+- #{ (Word.count / 5000.0 * 100).round(1) }%"
  #       last_interval = Time.now
  #     end
  #     simplified = row[1]
  #     
  #     zidian = Character.new(simplified: simplified).zidian_word_entries #.first
  #     # zidian = Zidian.find(simplified)
  #     
  #   
  #     #if zidian.count > 0
  #     zidian.each do |z|
  #       # word = Word.create(simplified: simplified, english: Word.english_given_zidian_entry(z)) # zidian.first 
  #       
  #       word = Word.find_or_create_by(simplified: entry.simplified) do |w|
  #         w.english = Word.english_given_zidian_entry(z)
  #       end
  #       
  #       word.simplified.split(//).each do |c|
  #         character = Character.find_by simplified: c
  #         if character && !character.words.include?(word)
  #           word.characters << character
  #         end
  #       end
  #     end
  #   end 
  # end
  
  desc "Import words for all characters"
  task :zidian_for_all_characters => :environment do
    Character.all.order("id asc").each do |character|
      puts "#{ (character.id.to_f / Character.count.to_f * 100.0 ).round }%..." if character.id % 25 == 0
      character.zidian_word_entries(100).each do |entry|
        # if character.words.count < 100
          word = Word.find_or_create_by(simplified: entry.simplified) do |w|
            w.english = Word.english_given_zidian_entry(entry)
          end

          # This is probably already done by Zidian:
          # word.simplified.split(//).each do |c|
          #   character = Character.find_by simplified: c
          #   if character && !character.words.include?(word)
          #     word.characters << character
          #   end
          # end
          
          unless character.words.include?(word)
            character.words << word
          end
        # end
      end
    end
  end
  
  desc "Remove duplicates"
  task :remove_duplicates => :environment do
    query = "select count(*) from characters_words;"
    puts ActiveRecord::Base.connection.execute(query);
    
    Character.all.each do |c|
      c.words.to_a.reject{ |e| c.words.to_a.count(e) == 1 }.uniq.each do |duplicate|
        c.words.delete(duplicate) # Removes the original as well
        c.words << duplicate # put it back
      end
    end
    
    puts ActiveRecord::Base.connection.execute(query);
  end
end
