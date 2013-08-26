class Radical < ActiveRecord::Base
  default_scope -> { order(id: :asc) }
  
  # validates_uniqueness_of :simplified  # Exception: 罒 belongs to radical 112 and 109
  validates_length_of :simplified, :is => 1
  validates :position, :inclusion => 1..214
  validates_uniqueness_of :position, :scope => :variant, :unless => :variant, :message => "has already been taken. Is this a variant?"

  has_and_belongs_to_many :characters
  
  def currently_unmatched_characters 
    self.characters.where("characters.id not in (?)", Character.unmatched_by_first_screen_ids ).references(:character)
  end
  
  def with_synonym_characters
    return self.characters.group("characters.id") if self.synonyms.count == 0
    
    Character.joins(:radicals).where("radicals.id = ? OR radicals.id IN (?)", self.id, self.synonyms).group("characters.id")
  end
  
  def pinyin
    if self.variant
      simpl = Radical.where(variant: false, position: self.position).first.simplified
    else
      simpl = self.simplified
    end
    PinYin.of_string(simpl, :unicode).first
  end
  
  def to_s
    self.simplified
  end
  
  # This includes secondary and tertiary matches
  def first_screen_matches(warn)
    characters = []
    Radical.where("id in (?)", (self.first_screen ? [self.radicals, self.secondary_radicals].flatten : [])).each do |second_radical|      
      matches = self.characters.keep_if{|character| character.has_radicals(self, second_radical)}
      characters << matches.to_a.slice(0,35)
      if matches.count > 20 && warn 
        puts "#{ self } #{ second_radical } matches #{ matches.count } characters, 35 allowed."
      end
    end
    
    # Tertiary matches:
    tertiary_matches = []
    Radical.where("id in (?)", (self.first_screen ? [self.tertiary_radicals].flatten : [])).each do |second_radical|      
      tertiary_matches << self.characters.keep_if{|character| character.has_radicals(self, second_radical)}
    end
      
    # Show tertiary characters directly, so cut off at 35. Won't fit on one screen, 
    # but that's alright for these few exceptions
    tertiary_matches = tertiary_matches.flatten.uniq
    
    if tertiary_matches.count > 35 && warn
      puts "Ignoring #{ tertiary_matches.count - 35 } matches for #{ self }"
    end
    characters << tertiary_matches.to_a.slice(0,35)
    
    characters.flatten.uniq
  end
  
  # Does not include secondary or tertiary matches (because there aren't any)
  def second_screen_matches(warn)
    matching_characters = []
    Radical.where("id in (?)", self.radicals).each do |second_radical|
      matches = self.second_screen_potential_characters.to_a.keep_if{|character| character.has_radicals(self, second_radical)}
      matching_characters << matches
      if matches.count > 20 && warn
        puts "#{ first_radical } #{ second_radical } matches #{ matches.count } characters, 35 allowed."
      end
    end
    
    matching_characters.flatten.uniq.slice(0,35)
  end
  
  # Does not include secondary or tertiary matches (because there aren't any)
  def third_screen_matches(warn)
    matching_characters = []

    matches = self.third_screen_potential_characters.to_a.flatten.uniq
    
    if matches.count > 20 && warn
      puts "#{ self } in third screen matches #{ matches.count } characters, 35 allowed."
    end
    
    matches.slice(0,35)
  end
  
  def second_screen_potential_characters
    # self.characters.where(first_screen: false)
    Character.joins(:radicals).where(first_screen: false).where("radicals.id = ? OR radicals.id IN (?)", self.id, self.synonyms).group("characters.id")
  end
  
  def third_screen_potential_characters
    # self.characters.where(first_screen: false, second_screen: false)
    Character.joins(:radicals).where(first_screen: false, second_screen: false).where("radicals.id = ? OR radicals.id IN (?)", self.id, self.synonyms).group("characters.id")
    
  end
  
  def no_screen_characters
    # self.characters.where(first_screen: false, second_screen: false, third_screen: false, fourth_screen: false)
    Character.joins(:radicals).where(first_screen: false, second_screen: false, third_screen: false, fourth_screen: false).where("radicals.id = ? OR radicals.id IN (?)", self.id, self.synonyms).group("characters.id")
  end
  
  def tooltip
    tips = []
    if self.synonyms.length > 0
      tips << "Also " + Radical.where("id in (?)", self.synonyms).collect{|r| r.to_s}.join(" ")
    end
    
    if self.do_not_confuse && self.do_not_confuse.length > 0
      tips << "Not " + Radical.where("id in (?)", self.do_not_confuse).collect{|r| r.to_s}.join(" ")
    end
    
    tips.join("\n")
  end
  
  def self.first_screen_radicals
    self.where(first_screen: true)
  end
  
  def self.second_screen_by_frequency
    Radical.where("radicals.first_screen = ? and ambiguous = ? and is_synonym = ?", false, false, false).collect {|r|
      [r, r.with_synonym_characters.where("characters.first_screen = ?", false).to_a.count]
    }.sort_by{|a| -a[1] }.collect{|a| a[0]}
      # joins(:characters).where(first_screen: false).select('radicals.*, count("characters".id) as "character_count"').group("radicals.id").order('character_count desc')
  end
  
  def self.third_screen_by_frequency
    Radical.where("radicals.first_screen = ? and radicals.second_screen = ? and ambiguous = ? and is_synonym = ?", false, false, false, false).collect {|r|
      [r, r.with_synonym_characters.where("characters.first_screen = ? AND characters.second_screen = ?", false, false).to_a.count]
    }.sort_by{|a| -a[1] }.collect{|a| a[0]}
    
    # Radical.where("radicals.first_screen = ? and radicals.second_screen = ? and ambiguous = ? and is_synonym = ?", false, false, false).joins(:characters).where(first_screen: false, second_screen: false).select('radicals.*, count("characters".id) as "character_count"').group("radicals.id").order('character_count desc')
  end
  
  def self.no_screen_by_frequency
    Radical.where("radicals.first_screen = ? and radicals.second_screen = ?  and radicals.first_screen = ? and ambiguous = ? and is_synonym = ?", false, false, false, false, false).collect {|r|
      [r, r.with_synonym_characters.where("characters.first_screen = ? AND characters.second_screen = ? AND characters.second_screen = ?", false, false, false).to_a.count]
    }.sort_by{|a| -a[1] }.collect{|a| a[0]}
    
    
    # Radical.where("radicals.third_screen = ? and radicals.second_screen = ? and radicals.first_screen = ? and is_synonym = ?", false, false, false).joins(:characters).where("characters.first_screen = ? AND characters.second_screen = ? AND characters.third_screen = ? AND characters.fourth_screen = ?", false, false, false, false).select('radicals.*, count("characters".id) as "character_count"').group("radicals.id").order('character_count desc')
  end
  
  def self.make_synonyms(primary, synonyms)
    first = Radical.find_by(simplified: primary) 
    second = synonyms.collect {| synonym | Radical.find_by(simplified: synonym) }
    
    first.update synonyms: second.collect{|s| s.id}
    second.each do |s|
      s.update is_synonym: true
    end
  end
  
  def self.export_screen_1_and_2_radicals(screen, f)
    if screen == 1
      @radicals = self.where(first_screen: true).to_a.slice(0,2) # DEBUG
    else
      @radicals = self.where(second_screen: true).to_a.slice(0,2) # DEBUG
    end
    
    @radicals.each_index do |i|
      first_radical = @radicals[i]
      puts "#{ first_radical }..."
      f << "  NSLog(@\"#{ first_radical }...\");\n"
      f << "  r = [NSEntityDescription insertNewObjectForEntityForName:kEntityRadical\n"  
      f << "               inManagedObjectContext:managedObjectContext];\n"
      f << "  r.isFirstRadical = @YES;\n"
      f << "  r.simplified = @\"#{ first_radical.simplified }\";\n"
      f << "  r.position = [NSNumber numberWithInt:#{ i }];\n"
      f << "  r.section = @#{ screen - 1 };\n"  
      f << "\n"
      primary_second_radicals = Radical.where("id in (?)", @radicals[i].radicals).to_a #.slice(0,5) # DEBUG
      self.export_second_radicals(primary_second_radicals, f, false, screen, :primary, first_radical)

      # Only first screen:
      if screen  == 1
        # These aren't on the second screen, because there just aren't enough to make it worth it.
        secondary_second_radicals = Radical.where("id in (?)", @radicals[i].secondary_radicals).to_a #.slice(0,5) # DEBUG
        self.export_second_radicals(secondary_second_radicals, f, false, 1, :secondary,first_radical)
        
       
        tertiary_second_radicals = Radical.where("id in (?)", @radicals[i].tertiary_radicals).to_a #.slice(0,5) # DEBUG
        # These are displayed as characters:
        @characters = []
    
        tertiary_second_radicals.each do |second_radical|      
          @characters << first_radical.with_synonym_characters.keep_if{|character| character.has_radicals(first_radical, second_radical)}
        end
    
        @characters.flatten!.uniq!.to_a.slice(0,35)

        f << "  r2 = r;";
        self.export_characters(f, @characters, first_radical)
        

      end

      self.export_save_context(f)
    end
    
  end
  
  def self.export_save_context(f)
    f << "\n"
    f << "  error = nil;\n"
    f << "  [managedObjectContext save:&error];\n"
    f << "  if(error != nil) { NSLog(@\"%@\", error); }"
    f << "\n\n"
  end
  
  def self.export_screen_3_radicals(f)
    radicals = self.where(third_screen: true).to_a #.slice(0,2) # DEBUG
    self.export_second_radicals(radicals, f, true, 3, :primary, nil)
    self.export_save_context(f)
  end
  
  def self.export_screen_4_radicals(f)
    self.export_characters(f, Character.where(fourth_screen: true), nil)
    self.export_save_context(f)
  end
  
  def self.export_second_radicals(second_radicals, f, without_first_radical, screen, primary_secondary, first_radical)
    pmt = 1 if primary_secondary == :primary
    pmt = 2 if primary_secondary == :secondary
        
    second_radicals.each_index do |j|
      second_radical = second_radicals[j]
      f << "  r2 = [NSEntityDescription insertNewObjectForEntityForName:kEntityRadical\n"  
      f << "               inManagedObjectContext:managedObjectContext];\n"
      f << "  r2.isFirstRadical = @NO;\n"
      
      if without_first_radical
        f << "  r2.section = @2;\n"  
      else
        f << "  r2.firstRadical = r;\n"
        f << "  r2.section = @#{ pmt - 1 };\n"  
      end
      f << "  r2.simplified = @\"#{ second_radical.simplified }\";\n"
      f << "  r2.position = [NSNumber numberWithInt:#{ j }];\n"
      if screen == 1
        @characters = first_radical.with_synonym_characters.where(first_screen: true).keep_if{|c| c.has_radicals(first_radical, second_radical)}
      elsif screen == 2
        @characters = first_radical.with_synonym_characters.where(second_screen: true).keep_if{|c| c.has_radicals(first_radical, second_radical)}
      elsif screen == 3
        @characters = second_radical.with_synonym_characters.where(third_screen: true).to_a
      end
    
      self.export_characters(f, @characters, second_radical)
    end
  end
  
  def self.export_characters(f, characters, second_radical)
    f << "  cTally = 0;\n"
    f << "  for(NSArray *character_words in @[\n" 
    character_count = characters.count
    characters.each_index do |k| 
      character = characters[k]
      f << "    @["
      f << "@\"#{ character.simplified }\", "
      f << "@[" + character.words.collect{|w| "@[@\"#{ w.simplified }\", @\"#{ w.english.collect{| e | e.gsub("\"","\\\"")}.join('; ') }\"]" }.join(", ") + "]"
      if k <= character_count - 2
        f << "],\n"
      else
        f << "]\n"
      end
    end
    f << "  ]) {\n"
    f << "    Character* c;\n"
    f << "    NSString *character = [character_words firstObject];\n"
    f << "    c = [Character fetchBySimplified:character inManagedObjectContext:managedObjectContext];\n"
    f << "    if( c==nil ) {\n"
    f << "      c = [NSEntityDescription insertNewObjectForEntityForName:kEntityCharacter inManagedObjectContext:managedObjectContext];\n"
    f << "      c.simplified = character;\n"
    f << "      c.position = [NSNumber numberWithInt:cTally];\n"
    f << "      int wTally = 0;\n"
    f << "      for(NSArray *simplified_english in [character_words lastObject]) {\n"
    f << "        Word* w;\n"
    f << "        w = [Word fetchBySimplified:[simplified_english firstObject] inManagedObjectContext:managedObjectContext];\n"
    f << "        if( w==nil ) {\n"
    f << "          w = [NSEntityDescription insertNewObjectForEntityForName:kEntityWord inManagedObjectContext:managedObjectContext];\n"
    f << "          w.simplified = [simplified_english firstObject];\n"
    f << "          w.english = [simplified_english lastObject];\n"
    f << "          w.wordLength = [NSNumber numberWithInt:[w.simplified length]];\n" 
    f << "        }\n"
    f << "        [w addCharactersObject:c];\n"
    f << "        wTally++;\n"
    f << "      }\n"
    f << "    }\n"
    if second_radical.present?
      f << "    [c addSecondRadicalsObject:r2];\n"
    end
    f << "  }\n"
    f << "\n"
  end
  
end
