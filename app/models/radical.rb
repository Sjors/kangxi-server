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
      characters << matches
      if matches.count > 20 && warn
        puts "#{ self } #{ second_radical } matches #{ matches.count } characters."
      end
    end
    
    # Tertiary matches:
    tertiary_matches = []
    Radical.where("id in (?)", (self.first_screen ? [self.tertiary_radicals].flatten : [])).each do |second_radical|      
      tertiary_matches << self.characters.keep_if{|character| character.has_radicals(self, second_radical)}
    end
      
    # Show tertiary characters directly, so cut off at 20
    if tertiary_matches.count > 20 && warn
      puts "Ignoring #{ tertiary_matches.count - 20 } matches for #{ self }"
    end
    characters <<  tertiary_matches.slice(0,20)
    
    characters.flatten.uniq
  end
  
  # Does not include secondary or tertiary matches (because there aren't any)
  def second_screen_matches(warn)
    matching_characters = []
    Radical.where("id in (?)", self.radicals).each do |second_radical|
      matches = self.second_screen_characters.to_a.keep_if{|character| character.has_radicals(self, second_radical)}
      matching_characters << matches
      if matches.count > 20 && warn
        puts "#{ first_radical } #{ second_radical } matches #{ matches.count } characters."
      end
    end
    
    matching_characters.flatten.uniq
  end
  
  def second_screen_characters
    self.characters.to_a - self.first_screen_matches(false).to_a
  end
  
  def no_screen_characters
    self.characters.to_a - self.first_screen_matches(false).to_a - self.second_screen_matches(false).to_a
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
  
  def self.second_screen_frequent_for_characters(characters)
    Radical.where("radicals.first_screen = ? and ambiguous = ?", false, false).joins(:characters).where("characters.id not in (?)", characters.collect{|c| c.id}).select('radicals.*, count("characters".id) as "character_count"').group("radicals.id").order('character_count desc')
  end
  
  def self.no_screen_frequent_for_characters(characters)
    Radical.where("radicals.second_screen = ? and radicals.first_screen = ? and ambiguous = ?", false, false, false).joins(:characters).where("characters.id not in (?)", characters.collect{|c| c.id}).select('radicals.*, count("characters".id) as "character_count"').group("radicals.id").order('character_count desc')
  end
  
  def self.second_screen_plus_one_radical_character_matches(warn)
    characters = []
    
    self.where(second_screen: true).each do |first_radical|
      characters << first_radical.second_screen_matches(warn)
    end
    
    characters.flatten.uniq
  end
end
