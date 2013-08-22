namespace :organize do 
  task :all => [:clean, :ambiguous, :first_screen, :divide_first_screen, :second_screen, :divide_second_screen, :third_screen, :divide_third_screen, :report]
  
  desc "Clean"
  task :clean => :environment do
    Character.update_all("first_screen = false, second_screen = false, third_screen = false")
    Radical.update_all("ambiguous = false, first_screen = false, second_screen = false, third_screen = false, frequency = 0, second_screen_frequency = 0, third_screen_frequency = 0, radicals = '{}', secondary_radicals = '{}', tertiary_radicals = '{}'")    
  end
  
  desc "Group radicals"
  task :ambiguous => :environment do
    @radicals = %w(一 丨 丶 丿 亅 乚 乛 𠃌 𠃊)
    Radical.all.each do |radical|
      radical.update(ambiguous: @radicals.include?(radical.simplified))
    end
  end

  desc "First Screen"
  task :first_screen => :environment do
    @radicals = %w(人 亻 土 日 月 木 艹 讠 宀 又 禾 十 亠 口 田 氵 丷 扌 大 厶)
    Radical.all.each do |radical|
      radical.update(first_screen: @radicals.include?(radical.simplified), frequency: radical.characters.count)
    end
  end
  
  task :divide_first_screen => :environment do 
    Radical.where(first_screen: true).order(:frequency => :desc).each do |first_radical|
      radicals = []
      first_radical.characters.each  do |character|
        radicals << character.radicals.to_a.subtract_once(first_radical)
      end
      
      radicals = radicals.flatten.uniq.reject{|radical| radical.ambiguous }
   
      unless Rails.env == "production"
        puts "\n\n\n" + first_radical.simplified + " " + radicals.count.to_s + " unqique non-ambiguous second radicals"
        puts ""
      end
  
      frequencies = []
  
      radicals.each do |radical| 
        characters = first_radical.characters.keep_if{|character| character.has_radicals(first_radical, radical) }
        frequency = characters.count
        frequencies << [radical, frequency, characters]
      end
  
      frequencies.sort_by!{|frequency| [(frequency[0] == first_radical ? 0 : 1) , ((frequency[0].first_screen && frequency[0].frequency < first_radical.frequency)  ? 1 : 0),-frequency[1]]}
  
      # unless Rails.env == "production"        
      #   frequencies.each do |frequency|
      #     puts frequency[0].simplified + " " + frequency[1].to_s
      #   end
      # end
  
      first_radical.update radicals: frequencies.slice(0,20).collect{|f| f[0].id}
      
      if frequencies.count > 20
        first_radical.update secondary_radicals: frequencies.slice(20,20).collect{|f| f[0].id} 
      end
      
      if frequencies.count > 40
        first_radical.update tertiary_radicals: frequencies.slice(40,20).collect{|f| f[0].id} 
      end
      
      frequencies.slice(0,60).collect{|f| f[2]}.flatten.uniq.each do |character|
        character.update first_screen: true
      end
    end
  end
    
  task :second_screen => :environment do
    
    matched_characters = Character.where(first_screen: true)
    puts "#{matched_characters.count} matched characters for first screen"
    
    unmatched_characters = Character.where(first_screen: false).includes(:radicals).where("radicals.id IS NOT NULL")
    puts "#{unmatched_characters.count} unmatched characters"
        
    @radicals = Radical.second_screen_by_frequency
    puts "#{@radicals.to_a.count} non-first-screen radicals in those unmatched characters"
          
    @frequencies =  @radicals.collect{|r| [r, (r.second_screen_potential_characters - [Character.find_by(simplified: r.simplified)]).count]}.sort_by{|r| -r[1]}     
              
    @frequencies.slice(0,20).each do |radical_frequency|
      radical = radical_frequency[0]
      frequency = radical_frequency[1]
      if frequency > 0
        radical.update(second_screen: true, second_screen_frequency: frequency)
        puts "#{radical} #{ radical.second_screen_frequency }"
      end
    end
  end

  task :divide_second_screen => :environment do 
    Radical.where(second_screen: true).order(:second_screen_frequency => :desc).each do |first_radical|
      radicals = []
      first_radical.second_screen_potential_characters.each  do |character|
        radicals << character.radicals.to_a.subtract_once(first_radical)
      end
    
    
      radicals = radicals.flatten.uniq.reject{|radical| radical.ambiguous || Radical.first_screen_radicals.include?(radical) }
       
      unless Rails.env == "production"
        puts "\n\n\n" + first_radical.simplified + " " + radicals.count.to_s + " unique second radicals that don't occur in the first screen"
        puts ""
      end
      
      frequencies = []
      
      radicals.each do |radical| 
        characters = first_radical.second_screen_potential_characters.keep_if{|character| character.has_radicals(first_radical, radical) }
        frequency = characters.count
        frequencies << [radical, frequency, characters]
      end
      
      frequencies.sort_by!{|frequency| [(frequency[0] == first_radical ? 0 : 1) , ((frequency[0].second_screen && frequency[0].second_screen_frequency < first_radical.second_screen_frequency)  ? 1 : 0),-frequency[1]]}
      
      
      unless Rails.env == "production"        
        frequencies.each do |frequency|
          puts frequency[0].simplified + " " + frequency[1].to_s
        end
      end
            
      first_radical.update radicals: frequencies.slice(0,20).collect{|f| f[0].id }
      
      frequencies.slice(0,20).collect{|f| f[2]}.flatten.uniq.each do |character|
        character.update second_screen: true
      end
    end
  end
  
  task :third_screen => :environment do
    Radical.update_all(third_screen: false, third_screen_frequency: 0)
    Character.update_all(third_screen: false)
    
    matched_characters = Character.where("first_screen = ? OR second_screen = ?", true, true)
    
    puts "#{matched_characters.count} matched characters for first and second screen"
    
    unmatched_characters = Character.where(first_screen: false, second_screen: false).includes(:radicals).where("radicals.id IS NOT NULL")
    puts "#{unmatched_characters.count} unmatched characters (including single radicals)"
        
    @radicals = Radical.third_screen_by_frequency
    puts "#{@radicals.to_a.count} non-first and non-second screen radicals in those unmatched characters, including single radicals"
    
    # The third screen shows the characters directly, no radicals      
    @frequencies =  @radicals.collect{|r| [r, r.third_screen_potential_characters.count, r.third_screen_potential_characters]}.sort_by{|r| -r[1]}     
              
    @frequencies.slice(0,20).each do |radical_frequency|
      radical = radical_frequency[0]
      frequency = radical_frequency[1]
      if frequency > 0
        radical.update(third_screen: true, third_screen_frequency: frequency)
        puts "#{radical} #{ radical.third_screen_frequency }"
      end
      
      radical_frequency[2].each do |c|
        c.update third_screen: true
      end
      
    end
  end

  task :divide_third_screen => :environment do 
    # We show only the characters, so nothing to do here...
  end
  
  task :report => :environment do
    @characters = []
    
    matched_characters_1 = Radical.first_screen_plus_one_radical_character_matches(Rails.env != "production")
    
    matched_characters_2 = Radical.second_screen_plus_one_radical_character_matches(Rails.env != "production")
        
    matched_characters_3 = Radical.third_screen_character_matches(Rails.env != "production")
        
    matched_characters = [matched_characters_1, matched_characters_2, matched_characters_3].flatten.uniq

    puts "#{ matched_characters.count } characters can be found in 3 clicks"
        
    unmatched_characters = Character.where(first_screen: false, second_screen: false, third_screen: false).includes(:radicals).where("radicals.id IS NOT NULL")
    puts "#{unmatched_characters.count} unmatched characters, including single radicals."
  end
  
  task :excluded => :environment do
    matched_characters_1 = Radical.first_screen_plus_one_radical_character_matches(false)
    matched_characters_2 = Radical.second_screen_plus_one_radical_character_matches(false)
            
    matched_characters = [matched_characters_1, matched_characters_2].flatten.uniq
 
    unmatched_characters = Character.all.includes(:radicals).where("radicals.id IS NOT NULL").to_a - matched_characters.to_a - Character.single_radicals.to_a
  
    puts "#{ matched_characters.count } characters can be found in 3 clicks"
    puts "#{unmatched_characters.count} unmatched characters."
  
    @radicals = Radical.no_screen_frequent_for_characters(unmatched_characters)
    puts "#{@radicals.to_a.count} non-first and non-second-screen radicals in those unmatched characters"
          
    @frequencies =  @radicals.collect{|r| [r, (r.no_screen_characters - matched_characters - [Character.find_by(simplified: r.simplified)]).count]}.sort_by{|r| -r[1]}     
          
    @frequencies.each do |radical_frequency|
      radical = radical_frequency[0]
      frequency = radical_frequency[1]
      if frequency > 0
        puts "#{radical} #{ frequency }: #{ (radical.no_screen_characters - matched_characters - [Character.find_by(simplified: radical.simplified)]).join(' ') }"
      end
    end
  
  
  
 
  end
end
