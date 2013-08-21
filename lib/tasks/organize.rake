namespace :organize do 
  task :all => [:ambiguous, :first_screen, :divide, :report]
  
  desc "Group radicals"
  task :ambiguous => :environment do
    @radicals = %w(一 丨 丶 丿 亅 乚 乛 𠃌 𠃊)
    Radical.all.each do |radical|
      radical.update(ambiguous: @radicals.include?(radical.simplified))
    end
  end
  
  task :first_screen => :environment do
    # %w(人 亻 土 日 月 木 艹 讠 宀 又 禾 冖 小 夕 勹 丨 丿 二 乛 卜)
    @radicals = %w(人 亻 土 日 月 木 艹 讠 宀 又 禾 冖 小 夕 勹  二 卜 口 田 氵)
    Radical.all.each do |radical|
      radical.update(first_screen: @radicals.include?(radical.simplified))
    end
    
  end
  
  task :divide => :environment do 
    Radical.all.each do |first_radical|
      if first_radical.first_screen
        radicals = first_radical.characters.collect{|character| character.radicals}.flatten.uniq.reject{|radical| radical == first_radical || radical.ambiguous}
     
        unless Rails.env == "production"
          puts "\n\n\n" + first_radical.simplified + " " + radicals.count.to_s
          puts ""
        end
    
        frequencies = []
    
        radicals.each do |radical| 
          frequency = first_radical.characters.keep_if{|character| character.radicals.include?(radical) }.count
          frequencies << [radical, frequency]
        end
    
        frequencies.sort_by!{|frequency| -frequency[1]}
    
        unless Rails.env == "production"        
          frequencies.each do |frequency|
            puts frequency[0].simplified + " " + frequency[1].to_s
          end
        end
    
        first_radical.update radicals: frequencies.slice(0,19).collect{|f| f[0].id }
      else
        first_radical.update radicals: []
      end
    end
  end
  
  task :report => :environment do
    @characters = []
    Radical.where(first_screen: true).each do |first_radical|
      Radical.where("id in (?)", first_radical.radicals).each do |second_radical|
        matches = first_radical.characters.keep_if{|c| c.radicals.include?(second_radical)}
        @characters << matches
        if matches.count > 20
          unless Rails.env == "production"
            puts "#{ first_radical } #{ second_radical } matches #{ matches.count } characters."
          end
        end
      end
    end
    
    puts "#{ @characters.uniq.count } characters can be found in 2 clicks"
  end
end
