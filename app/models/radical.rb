class Radical < ActiveRecord::Base
  # validates_uniqueness_of :simplified  # Exception: 罒 belongs to radical 112 and 109
  validates_length_of :simplified, :is => 1
  validates :position, :inclusion => 1..214
  validates_uniqueness_of :position, :scope => :variant, :unless => :variant, :message => "has already been taken. Is this a variant?"

  has_and_belongs_to_many :characters
  
  def rank
    tally = self.position * 10
    
    if self.variant
      tally = tally + Radical.where(position: self.position).order(variant: :asc).collect{|v| v.id}.find_index(self.id)
    end
    
    return tally
  end
  
  def with_synonym_characters
    return self.characters.group("characters.id") if self.synonyms.count == 0
    Character.joins(:radicals).where("level = 1 OR level = 2").where("radicals.id = ? OR radicals.id IN (?)", self.id, self.synonyms).group("characters.id")
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
  
  def matches(warn)
    characters = []
    Radical.where("id in (?)", self.radicals).each do |second_radical|      
      matches = self.characters.keep_if{|character| character.has_radicals(self, second_radical)}
      characters << matches.to_a.slice(0,50)
      if matches.count > 50 && warn 
        puts "#{ self } #{ second_radical } matches #{ matches.count } characters, 50 allowed."
      end
    end
    
    characters.flatten.uniq
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
  
  def self.make_synonyms(primary, synonyms)
    first = Radical.find_by(simplified: primary) 
    second = synonyms.collect {| synonym | Radical.find_by(simplified: synonym) }
    
    first.update synonyms: second.collect{|s| s.id}
    second.each do |s|
      s.update is_synonym: true
    end
  end
  
  def self.export_radicals(f)
    self.where(is_synonym: false).where("frequency < ?", 100).order(frequency: :desc).limit(100).each do |first_radical|
      f << "@autoreleasepool {\n"
      puts "#{ first_radical }..."
      f << "  NSLog(@\"#{ first_radical }...\");\n"
      f << "  r = [NSEntityDescription insertNewObjectForEntityForName:kEntityRadical\n"  
      f << "               inManagedObjectContext:managedObjectContext];\n"
      f << "  r.isFirstRadical = @YES;\n"
      f << "  r.simplified = @\"#{ first_radical.simplified }\";\n"
      f << "  r.rank = @#{ first_radical.rank };\n"
      f << "  r.section = @#{ 0 };\n"  
      f << "\n"
      primary_second_radicals = Radical.where("id in (?)", first_radical.radicals).to_a #.slice(0,5) # DEBUG
      self.export_second_radicals(primary_second_radicals, f, false, first_radical)

      self.export_save_context(f)
      f << "}\n" # End of auto release pool
    end
    
  end
  
  def self.export_save_context(f)
    f << "\n"
    f << "  r = nil;\n"
    f << "  r2 = nil;\n"
    f << "  error = nil;\n"
    f << "  [managedObjectContext save:&error];\n"
    f << "  if(error != nil) { NSLog(@\"%@\", error); abort();}\n"
    f << "  [managedObjectContext reset];\n"
    f << "\n\n"
  end
  
  def self.export_second_radicals(second_radicals, f, without_first_radical, first_radical)
    second_radicals.each do |second_radical|
      f << "  r2 = [NSEntityDescription insertNewObjectForEntityForName:kEntityRadical\n"  
      f << "               inManagedObjectContext:managedObjectContext];\n"
      f << "  r2.isFirstRadical = @NO;\n"
      
      if without_first_radical
        f << "  r2.section = @2;\n"  
      else
        f << "  r2.firstRadical = r;\n"
        f << "  r2.section = @#{ 0 };\n"  
      end
      f << "  r2.simplified = @\"#{ second_radical.simplified }\";\n"
      f << "  r2.rank = @#{ second_radical.rank };\n"
      @characters = first_radical.with_synonym_characters.keep_if{|c| c.has_radicals(first_radical, second_radical)}
    
      self.export_characters(f, @characters, second_radical)
    end
  end
  
  def self.export_characters(f, characters, second_radical)
    f << "  for(NSArray *character_words in @[\n" 
    character_count = characters.count
    characters.each_index do |k| 
      character = characters[k]
      f << "    @["
      f << "@[@\"#{ character.simplified }\", @#{ character.rank }], "
            
      f << "@[" + character.words.collect{|w| "@[@\"#{ w.simplified }\", @\"#{ w.english.collect{| e | e.gsub("\"","\\\"")}.join('; ') }\"]" }.join(", ") + "]"
      if k <= character_count - 2
        f << "],\n"
      else
        f << "]\n"
      end
    end
    f << "  ]) {\n"
    f << "    Character* c;\n"
    f << "    NSArray *character = [character_words firstObject];\n"
    f << "    c = [Character fetchBySimplified:[character firstObject] inManagedObjectContext:managedObjectContext includesPropertyValuesAndSubentities:NO];\n"
    f << "    if( c==nil ) {\n"
    f << "      c = [NSEntityDescription insertNewObjectForEntityForName:kEntityCharacter inManagedObjectContext:managedObjectContext];\n"
    f << "      c.simplified = [character firstObject];\n"
    f << "      c.rank = [character lastObject];\n"
    f << "      for(NSArray *simplified_english in [character_words lastObject]) {\n"
    f << "        Word* w;\n"
    f << "        w = [Word fetchBySimplified:[simplified_english firstObject] inManagedObjectContext:managedObjectContext includesPropertyValuesAndSubentities:NO];\n"
    f << "        if( w==nil ) {\n"
    f << "          w = [NSEntityDescription insertNewObjectForEntityForName:kEntityWord inManagedObjectContext:managedObjectContext];\n"
    f << "          w.simplified = [simplified_english firstObject];\n"
    f << "          w.english = [simplified_english lastObject];\n"
    f << "          w.wordLength = [NSNumber numberWithInt:[w.simplified length]];\n" 
    f << "        }\n"
    f << "        [w addCharactersObject:c];\n"
    f << "      }\n"
    f << "    }\n"
    if second_radical.present?
      f << "    [c addSecondRadicalsObject:r2];\n"
    end
    f << "  }\n"
    f << "\n"
  end
  
  def self.export_synonyms(f)
    f << "+(void)synonyms:(NSManagedObjectContext *)managedObjectContext {\n"
    f << "  NSLog(@\"Synonyms\");\n"
    f << "  for(Radical *radical in [Radical all:managedObjectContext]) {\n"
    Radical.all.each do |r|
      if r.synonyms.count > 0 && r.simplified != "阝" && r.simplified != "罒"
        f << "    if ([radical.simplified isEqualToString:@\"#{ r.simplified }\"]) {\n"
        f << "      radical.synonyms = @\"#{ Radical.where("id in (?)", r.synonyms).collect{| s | s.simplified}.join(" ") }\";\n"
        f << "    }\n"
      end
    end
    f << "  }\n"
    f << "                                  \n"
    f << "  NSError *error;\n"
    f << "  [managedObjectContext save:&error];\n"
    f << "  if(error) { NSLog(@\"%@\",error); abort();}\n"
    f << "}\n"
    
  end
  
end
