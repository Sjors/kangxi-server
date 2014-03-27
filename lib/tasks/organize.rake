namespace :organize do 
  task :all => [:clean, :ambiguous, :synonyms, :confuse, :first_screen, :divide_first_screen, :second_screen, :divide_second_screen, :third_screen, :fourth_screen, :report]
  task :lite => [:clean, :ambiguous, :synonyms, :confuse, :first_screen_lite, :divide_first_screen_lite, :second_screen_lite, :divide_second_screen_lite, :third_screen_lite, :fourth_screen_lite, :report_lite]
  
  desc "Clean"
  task :clean => :environment do
    Character.update_all("first_screen = false, second_screen = false, third_screen = false, fourth_screen = false")
    Radical.update_all("ambiguous = false, first_screen = false, second_screen = false, third_screen = false, frequency = 0, second_screen_frequency = 0, third_screen_frequency = 0, radicals = '{}', secondary_radicals = '{}', tertiary_radicals = '{}', synonyms = '{}', is_synonym = false")    
  end
  
  desc "Group radicals"
  task :ambiguous => :environment do
    @radicals = %w(一 丨 丶 丿 亅 乛 𠃊)
    Radical.all.each do |radical|
      radical.update(ambiguous: @radicals.include?(radical.simplified))
    end
  end
  
  desc "Synonyms"
  task :synonyms => :environment do
    # yì and fù
    yi_fu = Radical.where(simplified: "阝")
    yi_fu.first.update synonyms: [yi_fu.last.id]
    yi_fu.last.update is_synonym: true
    
    # wǎng and mù
    wang_mu = Radical.where(simplified: "罒")
    wang_mu.first.update synonyms: [wang_mu.last.id]
    wang_mu.last.update is_synonym: true
    
    Radical.make_synonyms("土", ["士"])
    Radical.make_synonyms("口", ["囗"])
    Radical.make_synonyms("厂", ["广", "疒"])
    Radical.make_synonyms("𠃌", ["勹", "刀", "力"])
    Radical.make_synonyms("冂", %w(风 用 禸 肉 雨))
    Radical.make_synonyms("王", %w(玉))
    Radical.make_synonyms("冖", %w(宀))
    Radical.make_synonyms("夂", %w(夊))
    Radical.make_synonyms("又", %w(殳))
    Radical.make_synonyms("月", %w(⺼ 骨))
    Radical.make_synonyms("乚", %w(匕 比 毛))
    Radical.make_synonyms("毌", %w(毌))
    Radical.make_synonyms("肀", %w(聿))
    Radical.make_synonyms("夕", %w(舛))
    Radical.make_synonyms("巳", %w(色 己 已 邑))
    Radical.make_synonyms("贝", %w(见))
    Radical.make_synonyms("尸", %w(户 戶))
    Radical.make_synonyms("亻", %w(隹))
    Radical.make_synonyms("夕", %w(歹))
    Radical.make_synonyms("厶", %w(镸))
    Radical.make_synonyms("臼", %w(鼠))
    
  end
  
  desc "Mark confusing characters (for toolips)"
  task :confuse => :environment do
    Radical.update_all do_not_confuse: []
    # Radical.find_by(simplified: "土").update do_not_confuse: [Radical.find_by(simplified: "士").id]
    # Radical.find_by(simplified: "士").update do_not_confuse: [Radical.find_by(simplified: "土").id]
    # Radical.find_by(simplified: "口").update do_not_confuse: [Radical.find_by(simplified: "囗").id]
    # Radical.find_by(simplified: "囗").update do_not_confuse: [Radical.find_by(simplified: "口").id]
  end

  desc "First Screen"
  task :first_screen => :environment do
    @radicals = %w(人 亻 土 日 月 木 艹 讠 宀 又 禾 十 亠 口 田 氵 丷 扌 大 厶)
    # @radicals = %w(人 亻 日 月 木 艹 辶 讠 宀 亠 又 禾 十 田 氵 丷 扌 大 厶 冂)
    
    Radical.all.each do |radical|
      radical.update(first_screen: @radicals.include?(radical.simplified), frequency: radical.with_synonym_characters.to_a.count)
    end
  end
  
  task :divide_first_screen => :environment do 
    @character_ids = []
    
    Radical.where(first_screen: true).order(:frequency => :desc).each do |first_radical|
      radicals = []
      first_radical.with_synonym_characters.each  do |character|
        radicals << character.substract_once_with_synonyms(first_radical)
      end
      
      radicals = radicals.flatten.uniq.reject{|radical| radical.ambiguous || radical.is_synonym }
   
      unless Rails.env == "production" && radicals.count <= 20
        puts "\n\n\n" + first_radical.simplified + " " + radicals.count.to_s + " unique non-ambiguous non-synonym second radicals"
        puts ""
      end
  
      frequencies = []
  
      radicals.each do |radical| 
        characters = first_radical.with_synonym_characters.keep_if{|character| character.has_radicals(first_radical, radical) }
        frequency = characters.count
        frequencies << [radical, frequency, characters.collect{|c| c.id}]
      end
  
      frequencies.sort_by!{|frequency| [(frequency[0] == first_radical ? 0 : 1) , ((frequency[0].first_screen && frequency[0].frequency < first_radical.frequency)  ? 1 : 0),-frequency[1]]}
  
      unless Rails.env == "production"        
        frequencies.each do |frequency|
          puts frequency[0].simplified + Radical.where("id in (?)",frequency[0].synonyms).collect{|r| r.simplified}.join(" ") + " " + frequency[1].to_s
        end
      end
  
      first_radical.update radicals: frequencies.slice(0,20).collect{|f| f[0].id}
      
      if frequencies.count > 20
        first_radical.update secondary_radicals: frequencies.slice(20,20).collect{|f| f[0].id} 
      end
      
      if frequencies.count > 40
        first_radical.update tertiary_radicals: frequencies.slice(40,20).collect{|f| f[0].id} 
      end
      
      @character_ids << frequencies.slice(0,60).collect{|f| f[2]}.flatten.uniq
    end
    
    Character.where("id in (?)", @character_ids.flatten.uniq).update_all first_screen: true
  end
  
  desc "First Screen Lite"
  task :first_screen_lite => :environment do
    @radicals = %w(人 亻 土 日 月 木 艹 讠 宀 又 禾 十 亠 口 田 氵 丷 扌 大 厶)
    
    Radical.all.each do |radical|
      radical.update(first_screen: @radicals.include?(radical.simplified), frequency: radical.with_synonym_characters_lite.to_a.count)
    end
  end
  
  task :divide_first_screen_lite => :environment do 
    @character_ids = []
    
    Radical.where(first_screen: true).order(:frequency => :desc).each do |first_radical|
      radicals = []
      first_radical.with_synonym_characters_lite.each  do |character|
        radicals << character.substract_once_with_synonyms(first_radical)
      end
      
      radicals = radicals.flatten.uniq.reject{|radical| radical.ambiguous || radical.is_synonym }
   
      unless Rails.env == "production" && radicals.count <= 20
        puts "\n\n\n" + first_radical.simplified + " " + radicals.count.to_s + " unique non-ambiguous non-synonym second radicals"
        puts ""
      end
  
      frequencies = []
  
      radicals.each do |radical| 
        characters = first_radical.with_synonym_characters_lite.keep_if{|character| character.has_radicals(first_radical, radical) }
        frequency = characters.count
        frequencies << [radical, frequency, characters.collect{|c| c.id}]
      end
  
      frequencies.sort_by!{|frequency| [(frequency[0] == first_radical ? 0 : 1) , ((frequency[0].first_screen && frequency[0].frequency < first_radical.frequency)  ? 1 : 0),-frequency[1]]}
  
      unless Rails.env == "production"        
        frequencies.each do |frequency|
          puts frequency[0].simplified + Radical.where("id in (?)",frequency[0].synonyms).collect{|r| r.simplified}.join(" ") + " " + frequency[1].to_s
        end
      end
  
      first_radical.update radicals: frequencies.slice(0,20).collect{|f| f[0].id}
      
      if frequencies.count > 20
        first_radical.update secondary_radicals: frequencies.slice(20,20).collect{|f| f[0].id} 
      end
      
      if frequencies.count > 40
        first_radical.update tertiary_radicals: frequencies.slice(40,20).collect{|f| f[0].id} 
      end
      
      @character_ids << frequencies.slice(0,60).collect{|f| f[2]}.flatten.uniq
    end
    
    Character.where("id in (?)", @character_ids.flatten.uniq).update_all first_screen: true
  end
    
  task :second_screen => :environment do
    Radical.update_all(second_screen: false, second_screen_frequency: 0)
    Character.update_all(second_screen: false)
    
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
        unless Rails.env == "production"     
          puts "#{radical} #{ radical.second_screen_frequency }"
        end
      end
    end
  end

  task :divide_second_screen => :environment do 
    @character_ids = []
    
    Radical.where(second_screen: true).order(:second_screen_frequency => :desc).each do |first_radical|
      radicals = []
      first_radical.second_screen_potential_characters.each  do |character|
        # radicals << character.radicals.to_a.subtract_once(first_radical)
        radicals << character.substract_once_with_synonyms(first_radical)
      end
    
    
      radicals = radicals.flatten.uniq.reject{|radical| radical.ambiguous || radical.is_synonym || Radical.first_screen_radicals.include?(radical) }
       
      unless Rails.env == "production" && radicals.count <= 20
        puts "\n\n\n" + first_radical.simplified + " " + radicals.count.to_s + " unique second radicals that don't occur in the first screen"
        puts ""
      end
      
      frequencies = []
      
      radicals.each do |radical| 
        characters = first_radical.second_screen_potential_characters.keep_if{|character| character.has_radicals(first_radical, radical) }
        frequency = characters.count
        frequencies << [radical, frequency, characters.collect{|c| c.id}]
      end
      
      frequencies.sort_by!{|frequency| [(frequency[0] == first_radical ? 0 : 1) , ((frequency[0].second_screen && frequency[0].second_screen_frequency < first_radical.second_screen_frequency)  ? 1 : 0),-frequency[1]]}
      
      
      unless Rails.env == "production"        
        frequencies.each do |frequency|
          puts frequency[0].simplified + " " + frequency[1].to_s
        end
      end
            
      first_radical.update radicals: frequencies.slice(0,20).collect{|f| f[0].id }
      
      @character_ids << frequencies.slice(0,20).collect{|f| f[2]}.flatten.uniq
       
    end
    
    Character.where("id in (?)", @character_ids.flatten.uniq).update_all second_screen: true
    
  end
  
  task :second_screen_lite => :environment do
    Radical.update_all(second_screen: false, second_screen_frequency: 0)
    Character.update_all(second_screen: false)
    
    matched_characters = Character.where(first_screen: true)
    puts "#{matched_characters.count} matched characters for first screen"
    
    unmatched_characters = Character.where("level = 1 OR level = 2").where(first_screen: false).includes(:radicals).where("radicals.id IS NOT NULL")
    puts "#{unmatched_characters.count} unmatched characters"
        
    @radicals = Radical.second_screen_by_frequency_lite
    puts "#{@radicals.to_a.count} non-first-screen radicals in those unmatched characters"
          
    @frequencies =  @radicals.collect{|r| [r, (r.second_screen_potential_characters_lite - [Character.where("level = 1 OR level = 2").find_by(simplified: r.simplified)]).count]}.sort_by{|r| -r[1]}     
              
    @frequencies.slice(0,20).each do |radical_frequency|
      radical = radical_frequency[0]
      frequency = radical_frequency[1]
      if frequency > 0
        radical.update(second_screen: true, second_screen_frequency: frequency)
        unless Rails.env == "production"     
          puts "#{radical} #{ radical.second_screen_frequency }"
        end
      end
    end
  end

  task :divide_second_screen_lite => :environment do 
    @character_ids = []
    
    Radical.where(second_screen: true).order(:second_screen_frequency => :desc).each do |first_radical|
      radicals = []
      first_radical.second_screen_potential_characters_lite.each  do |character|
        radicals << character.substract_once_with_synonyms(first_radical)
      end
    
    
      radicals = radicals.flatten.uniq.reject{|radical| radical.ambiguous || radical.is_synonym || Radical.first_screen_radicals.include?(radical) }
       
      unless Rails.env == "production" && radicals.count <= 20
        puts "\n\n\n" + first_radical.simplified + " " + radicals.count.to_s + " unique second radicals that don't occur in the first screen"
        puts ""
      end
      
      frequencies = []
      
      radicals.each do |radical| 
        characters = first_radical.second_screen_potential_characters_lite.keep_if{|character| character.has_radicals(first_radical, radical) }
        frequency = characters.count
        frequencies << [radical, frequency, characters.collect{|c| c.id}]
      end
      
      frequencies.sort_by!{|frequency| [(frequency[0] == first_radical ? 0 : 1) , ((frequency[0].second_screen && frequency[0].second_screen_frequency < first_radical.second_screen_frequency)  ? 1 : 0),-frequency[1]]}
      
      
      unless Rails.env == "production"        
        frequencies.each do |frequency|
          puts frequency[0].simplified + " " + frequency[1].to_s
        end
      end
            
      first_radical.update radicals: frequencies.slice(0,20).collect{|f| f[0].id }
      
      @character_ids << frequencies.slice(0,20).collect{|f| f[2]}.flatten.uniq
       
    end
    
    Character.where("id in (?)", @character_ids.flatten.uniq).update_all second_screen: true
  end
  
  task :third_screen => :environment do
    @character_ids = []
    
    Radical.update_all(third_screen: false, third_screen_frequency: 0)
    Character.update_all(third_screen: false)
    
    matched_characters = Character.where("first_screen = ? OR second_screen = ?", true, true)
    
    puts "#{matched_characters.count} matched characters for first and second screen"
    
    unmatched_characters = Character.where(first_screen: false, second_screen: false).includes(:radicals).where("radicals.id IS NOT NULL")
    puts "#{unmatched_characters.count} unmatched characters (including single radicals)"
        
    @radicals = Radical.third_screen_by_frequency
    puts "#{@radicals.to_a.count} non-first and non-second screen radicals in those unmatched characters, including single radicals"
    
    # The third screen shows the characters directly, no radicals      
    @frequencies =  @radicals.collect{|r| [r, r.third_screen_potential_characters.to_a.count, r.third_screen_potential_characters.to_a.collect{|c| c.id}]}.sort_by{|r| -r[1]}     
              
    @frequencies.slice(0,20).each do |radical_frequency|
      radical = radical_frequency[0]
      frequency = radical_frequency[1]
      if frequency > 0
        radical.update(third_screen: true, third_screen_frequency: frequency)
        unless Rails.env == "production" && frequency <= 20
          puts "#{radical} #{ radical.third_screen_frequency }"
        end
      end
      
      @character_ids << radical_frequency[2]
      
    end
    
    Character.where("id in (?)", @character_ids.flatten.uniq).update_all third_screen: true
    
  end
  
  task :third_screen_lite => :environment do
    @character_ids = []
    
    Radical.update_all(third_screen: false, third_screen_frequency: 0)
    Character.update_all(third_screen: false)
    
    matched_characters = Character.where("first_screen = ? OR second_screen = ?", true, true)
    
    puts "#{matched_characters.count} matched characters for first and second screen"
    
    unmatched_characters = Character.where("level = 1 OR level = 2").where(first_screen: false, second_screen: false).includes(:radicals).where("radicals.id IS NOT NULL")
    puts "#{unmatched_characters.count} unmatched characters (including single radicals)"
        
    @radicals = Radical.third_screen_by_frequency_lite
    puts "#{@radicals.to_a.count} non-first and non-second screen radicals in those unmatched characters, including single radicals"
    
    # The third screen shows the characters directly, no radicals      
    @frequencies =  @radicals.collect{|r| [r, r.third_screen_potential_characters_lite.to_a.count, r.third_screen_potential_characters_lite.to_a.collect{|c| c.id}]}.sort_by{|r| -r[1]}     
              
    @frequencies.slice(0,20).each do |radical_frequency|
      radical = radical_frequency[0]
      frequency = radical_frequency[1]
      if frequency > 0
        radical.update(third_screen: true, third_screen_frequency: frequency)
        unless Rails.env == "production" && frequency <= 20
          puts "#{radical} #{ radical.third_screen_frequency }"
        end
      end
      
      @character_ids << radical_frequency[2]
      
    end
    
    Character.where("id in (?)", @character_ids.flatten.uniq).update_all third_screen: true
    
  end

  task :fourth_screen => :environment do 
    # 50 characters with a preference for complex radicals
    unmatched_characters = Character.where(first_screen: false, second_screen: false, third_screen: false).includes(:radicals).where("radicals.id IS NOT NULL")
  
    unmatched_characters.sort_by{|a| -a.radicals.maximum(:position)}.slice(0,50).each do |c|
      c.update fourth_screen: true
    end
  end
  
  task :fourth_screen_lite => :environment do 
    # 50 characters with a preference for complex radicals
    unmatched_characters = Character.where("level = 1 OR level = 2").where(first_screen: false, second_screen: false, third_screen: false).includes(:radicals).where("radicals.id IS NOT NULL")
  
    unmatched_characters.sort_by{|a| -a.radicals.maximum(:position)}.each do |c|
      c.update fourth_screen: true
    end
  end
  
  task :report => :environment do
    matched_characters = Character.where("first_screen = ? OR second_screen = ? OR third_screen = ? OR fourth_screen = ?", true, true, true, true)


    puts "#{ matched_characters.count } characters can be found in 3 clicks"
        
    unmatched_characters = Character.where(first_screen: false, second_screen: false, third_screen: false, fourth_screen: false).includes(:radicals).where("radicals.id IS NOT NULL")
    puts "#{unmatched_characters.count} unmatched characters, including single radicals."
  end
  
  task :report_lite => :environment do
    matched_characters = Character.where("first_screen = ? OR second_screen = ? OR third_screen = ? OR fourth_screen = ?", true, true, true, true)


    puts "#{ matched_characters.count } characters can be found in 3 clicks"
        
    unmatched_characters = Character.where("level = 1 OR level = 2").where(first_screen: false, second_screen: false, third_screen: false, fourth_screen: false).includes(:radicals).where("radicals.id IS NOT NULL")
    puts "#{unmatched_characters.count} unmatched level 1/2 characters, including single radicals."
  end
  
  task :excluded => :environment do
    unmatched_characters = Character.where(first_screen: false, second_screen: false, third_screen: false, fourth_screen: false).includes(:radicals).where("radicals.id IS NOT NULL")
  
    puts "#{unmatched_characters.count} unmatched characters."
  
    @radicals = Radical.no_screen_by_frequency
    puts "#{@radicals.to_a.count} non-first, second, third radicals in those unmatched characters"
          
    @frequencies =  @radicals.collect{|r| [r, (r.no_screen_characters - [Character.find_by(simplified: r.simplified)]).count]}.sort_by{|r| -r[1]}     
          
    @frequencies.each do |radical_frequency|
      radical = radical_frequency[0]
      frequency = radical_frequency[1]
      if frequency > 0
        puts "#{radical} #{ frequency }: #{ (radical.no_screen_characters - [Character.find_by(simplified: radical.simplified)]).join(' ') }"
      end
    end
  end
end
