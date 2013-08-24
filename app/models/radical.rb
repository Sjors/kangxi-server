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
    
    if self.do_not_confuse.length > 0
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
end
