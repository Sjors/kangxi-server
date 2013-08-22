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
    self.characters.where(first_screen: false)
  end
  
  def third_screen_potential_characters
    self.characters.where(first_screen: false, second_screen: false)
  end
  
  def no_screen_characters
    self.characters.where(first_screen: false, second_screen: false, third_screen: false, fourth_screen: false)
  end
  
  def self.first_screen_radicals
    self.where(first_screen: true)
  end
  
  def self.first_screen_plus_one_radical_character_matches(warn)
    characters = []
    
    self.where(first_screen: true).each do |first_radical|
      characters << first_radical.first_screen_matches(warn)
    end
    
    characters.flatten.uniq
  end
  
  def self.second_screen_by_frequency
    Radical.where("radicals.first_screen = ? and ambiguous = ?", false, false).joins(:characters).where(first_screen: false).select('radicals.*, count("characters".id) as "character_count"').group("radicals.id").order('character_count desc')
  end
  
  def self.third_screen_by_frequency
    Radical.where("radicals.first_screen = ? and radicals.second_screen = ? and ambiguous = ?", false, false, false).joins(:characters).where(first_screen: false, second_screen: false).select('radicals.*, count("characters".id) as "character_count"').group("radicals.id").order('character_count desc')
  end
  
  def self.no_screen_by_frequency
    Radical.where("radicals.third_screen = ? and radicals.second_screen = ? and radicals.first_screen = ?", false, false, false).joins(:characters).where("characters.first_screen = ? AND characters.second_screen = ? AND characters.third_screen = ? AND characters.fourth_screen = ?", false, false, false, false).select('radicals.*, count("characters".id) as "character_count"').group("radicals.id").order('character_count desc')
  end
  
  def self.second_screen_plus_one_radical_character_matches(warn)
    characters = []
    
    self.where(second_screen: true).each do |first_radical|
      characters << first_radical.second_screen_matches(warn)
    end
    
    characters.flatten.uniq
  end
  
  def self.third_screen_character_matches(warn)
    characters = []
    
    self.where(third_screen: true).each do |first_radical|
      characters << first_radical.third_screen_matches(warn)
    end
    
    characters.flatten.uniq
  end
end
