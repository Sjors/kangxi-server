namespace :organize do 
  task :all => [:clean, :ambiguous, :synonyms, :freq_count, :divide, :demo]
  
  desc "Clean"
  task :clean => :environment do
    Radical.update_all("ambiguous = false, frequency = 0, radicals = '{}', synonyms = '{}', is_synonym = false")    
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
    # Radical.make_synonyms("臼", %w(鼠))
  end
  
  desc "Count frequencies"
  task :freq_count => :environment do
    Radical.all.each do |radical|
      radical.update(frequency: radical.with_synonym_characters.to_a.count)
    end
  end
  
  task :divide => :environment do 
    @character_ids = []
    
    Radical.order(:frequency => :desc).each do |radical|
      radicals = []
      radical.with_synonym_characters.each  do |character|
        radicals << character.substract_once_with_synonyms(radical)
      end
      
      radicals = radicals.flatten.uniq.reject{|radical| radical.ambiguous || radical.is_synonym }
   
      unless radicals.count <= 20
        puts "\n\n\n" + radical.simplified + " " + radicals.count.to_s + " unique non-ambiguous non-synonym second radicals"
        puts ""
      end
  
      frequencies = []
  
      radicals.each do |other_radical| 
        characters = radical.with_synonym_characters.keep_if{|character| character.has_radicals(radical, other_radical) }
        frequency = characters.count
        # frequencies << [other_radical, frequency, characters.collect{|c| c.id}]
        frequencies << [other_radical, frequency]
        
      end
  
      # frequencies.sort_by!{|frequency| [(frequency[0] == radical ? 0 : 1) , ((frequency[0].first_screen && frequency[0].frequency < radical.frequency)  ? 1 : 0),-frequency[1]]}
  
      frequencies.sort_by!{|frequency| -frequency[1]}
      
  
      radical.update radicals: frequencies.collect{|f| f[0].id}
    end
  end  
  
  desc "Mark radicals and characters for demo mode"
  task :demo => :environment do
    Radical.update_all("demo = false")
    Character.update_all("demo = false")
    
    Character.where(level: 1).each do |c|
      c.update demo: true
    end
    
    # Blacklist some characters:
    "今了零买候他书她习七他她九热吃椅打了作那语会五院二些来关兴六期八分".split(//).uniq.each do |c|
      Character.find_by(simplified: c).update demo: false
    end

    Character.where(demo: true).each do |c|
      c.radicals.where(demo: false).each do |r|
        r.update demo: true
      end
    end
    
    # Reduce the number of radicals in the demo for simplicity:
    Radical.find_by(simplified: "一").update demo: false 
    Radical.find_by(simplified: "丨").update demo: false
    Radical.find_by(simplified: "丶").update demo: false
    Radical.find_by(simplified: "丿").update demo: false    
    Radical.find_by(simplified: "二").update demo: false
    Radical.find_by(simplified: "丷").update demo: false
    Radical.find_by(simplified: "ハ").update demo: false
    Radical.find_by(simplified: "八").update demo: false 
    Radical.find_by(simplified: "𠃊").update demo: false
    Radical.find_by(simplified: "乛").update demo: false
    Radical.find_by(simplified: "卜").update demo: false
    
    
    
  end
end