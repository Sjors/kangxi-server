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
  
  def self.first_screen_plus_one_radical_character_matches(warn)
    characters = []
    
    self.where(first_screen: true).each do |first_radical|
      self.where("id in (?)", first_radical.radicals).each do |second_radical|
        matches = first_radical.characters.keep_if{|character| character.has_radicals(first_radical, second_radical)}
        characters << matches
        if matches.count > 20 && warn
          puts "#{ first_radical } #{ second_radical } matches #{ matches.count } characters."
        end
      end
    end
    
    characters.flatten.uniq
  end
  
  def self.second_screen_frequent_for_characters(characters)
    Radical.where("radicals.first_screen = ?", false).joins(:characters).where("characters.id not in (?)", characters.collect{|c| c.id}).select('radicals.*, count("characters".id) as "character_count"').group("radicals.id").order('character_count desc')
  end
end
