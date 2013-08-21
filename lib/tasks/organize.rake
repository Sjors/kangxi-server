namespace :organize do 
  task :all => [:ambiguous, :first_screen, :divide_first_screen, :second_screen, :divide_second_screen, :report]
  
  desc "Group radicals"
  task :ambiguous => :environment do
    @radicals = %w(一 丨 丶 丿 亅 乚 乛 𠃌 𠃊)
    Radical.all.each do |radical|
      radical.update(ambiguous: @radicals.include?(radical.simplified))
    end
  end
  
  task :first_screen => :environment do
    @radicals = %w(人 亻 土 日 月 木 艹 讠 宀 又 禾 十 亠 口 田 氵 丷 扌 大 厶)
    Radical.all.each do |radical|
      radical.update(first_screen: @radicals.include?(radical.simplified), frequency: radical.characters.count, second_screen: false)
    end
  end
  
  task :divide_first_screen => :environment do 
    Radical.all.order(:frequency => :desc).each do |first_radical|
      if first_radical.first_screen
        radicals = []
        first_radical.characters.each  do |character|
          radicals << character.radicals.to_a.subtract_once(first_radical)
        end
        
        
        radicals = radicals.flatten.uniq.reject{|radical| radical.ambiguous }
     
        unless Rails.env == "production"
          puts "\n\n\n" + first_radical.simplified + " " + radicals.count.to_s + " unqique second radicals"
          puts ""
        end
    
        frequencies = []
    
        radicals.each do |radical| 
          frequency = first_radical.characters.keep_if{|character| character.has_radicals(first_radical, radical) }.count
          frequencies << [radical, frequency]
        end
    
        frequencies.sort_by!{|frequency| [(frequency[0] == first_radical ? 0 : 1) , ((frequency[0].first_screen && frequency[0].frequency < first_radical.frequency)  ? 1 : 0),-frequency[1]]}
    
        unless Rails.env == "production"        
          frequencies.each do |frequency|
            puts frequency[0].simplified + " " + frequency[1].to_s
          end
        end
    
        first_radical.update radicals: frequencies.slice(0,20).collect{|f| f[0].id}, second_screen: false 
      else
        first_radical.update radicals: [], second_screen: false
      end
    end
  end
    
  task :second_screen => :environment do
    Radical.all.each do |r|
      r.update second_screen: false, second_screen_frequency: 0
    end
    
    matched_characters = Radical.first_screen_plus_one_radical_character_matches(false)
    puts "#{matched_characters.count} matched characters for first screen"
    
    unmatched_characters = Character.all.includes(:radicals).where("radicals.id IS NOT NULL").to_a - matched_characters
    puts "#{unmatched_characters.count} unmatched characters"
        
    @radicals = Radical.second_screen_frequent_for_characters(unmatched_characters)
    puts "#{@radicals.to_a.count} non-first-screen radicals in those unmatched characters"
          
    @frequencies =  @radicals.collect{|r| [r, r.second_screen_characters.count]}.sort_by{|r| -r[1]}     
          
    @frequencies.slice(0,20).each do |radical_frequency|
      radical = radical_frequency[0]
      radical.update(second_screen: true, second_screen_frequency: radical_frequency[1])
      puts "#{radical} #{ radical.second_screen_frequency }"
    end
  end

  task :divide_second_screen => :environment do 
    Radical.where(second_screen: true).order(:second_screen_frequency => :desc).each do |first_radical|
      radicals = []
      first_radical.second_screen_characters.each  do |character|
        radicals << character.radicals.to_a.subtract_once(first_radical)
      end
    
    
      radicals = radicals.flatten.uniq.reject{|radical| radical.ambiguous }
       
      unless Rails.env == "production"
        puts "\n\n\n" + first_radical.simplified + " " + radicals.count.to_s + " unique second radicals that don't occur in the first screen"
        puts ""
      end
      
      frequencies = []
      
      radicals.each do |radical| 
        frequency = first_radical.second_screen_characters.keep_if{|character| character.has_radicals(first_radical, radical) }.count
        frequencies << [radical, frequency]
      end
      
      frequencies.sort_by!{|frequency| [(frequency[0] == first_radical ? 0 : 1) , ((frequency[0].second_screen && frequency[0].second_screen_frequency < first_radical.second_screen_frequency)  ? 1 : 0),-frequency[1]]}
      
      
      unless Rails.env == "production"        
        frequencies.each do |frequency|
          puts frequency[0].simplified + " " + frequency[1].to_s
        end
      end
            
      first_radical.update radicals: frequencies.slice(0,20).collect{|f| f[0].id }
    end
  end
  
  task :report => :environment do
    @characters = []
    
    @characters << Radical.first_screen_plus_one_radical_character_matches(Rails.env == "production")
    
    @characters << Radical.second_screen_plus_one_radical_character_matches(Rails.env == "production")
    
    tally = @characters.flatten.uniq.count
    
    # Radical page has a link to Wikipedia, so also counts:
    tally = tally + Radical.where("first_screen = ? || second_screen = ?", true, true).count
    
    puts "#{ tally } characters can be found in 3 clicks"
  end
end
