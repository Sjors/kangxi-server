namespace :export do 
  task :all => [:radicals_characters,:characters_words,:synonyms]
  
  desc "Export radicals, characters, words and synomyms"
  
  task :radicals_characters => :environment do 
    File.open("/Users/sjors/Dropbox/Kangxi/iOs/KangxiRadicals/Kangxi Radicals/radicals_characters.json", 'w') do |f| 
      Radical.export_radicals_characters(f)
    end
  end
  
  task :characters_words => :environment do 
    File.open("/Users/sjors/Dropbox/Kangxi/iOs/KangxiRadicals/Kangxi Radicals/characters_words.json", 'w') do |f| 
      Radical.export_characters_words(f)
    end
  end

  task :synonyms => :environment do 
    File.open("/Users/sjors/Dropbox/Kangxi/iOs/KangxiRadicals/Kangxi Radicals/synonyms.json", 'w') do |f| 
      Radical.export_synonyms(f)
    end
  end
end