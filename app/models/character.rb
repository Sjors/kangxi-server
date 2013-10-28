class Character < ActiveRecord::Base
  validates_uniqueness_of :simplified
  validates_length_of :simplified, :is => 1
  
  validates_presence_of :level
  validates :level, :inclusion => 1..6 
  
  has_and_belongs_to_many :radicals, :after_add => :touch_self, :after_remove => :touch_self
  has_and_belongs_to_many :words
  
  
  self.per_page = 100
  
  # default_scope -> { order("level asc, characters.id asc") }
  
  def rank
    scores = self.radicals.where(ambiguous: false).order(position: :desc).collect{|r| r.position}.slice(0,3)
    
    tally = 0
    tally = tally + scores[0] * 1000000 if scores.count >= 1
    tally = tally + scores[1] * 1000 if scores.count >= 2
    tally = tally + scores[2] if scores.count >= 3
    
    return tally
  end
  
  def remove_radical(radical, count = 1)
    current_radical_count = self.radicals.where(id: radical.id).count
    self.radicals.delete(radical)
    (current_radical_count - count).times { self.radicals << radical }
  end
  
  def substract_once_with_synonyms(first_radical)
    if first_radical.synonyms.count == 0
      return self.radicals.to_a.subtract_once(first_radical)
    else # Substract no more than one of the synonyms; doesn't have to be the correct one.
      Radical.where("id = ? OR id in (?)", first_radical.id, first_radical.synonyms).each do |r|
        subtracted =  self.radicals.to_a.subtract_once(first_radical)
        if subtracted.length != self.radicals.to_a.length
          return subtracted
          break
        end
      end
    end
  end
  
  def self.unmatched_by_first_screen_ids
    self.includes(:radicals).where("radicals.first_screen = ?", true).references(:radicals).uniq.collect{|c| c.id}
  end
  
  def pinyin
    PinYin.of_string(self.simplified, :unicode).first
  end
  
  def to_s
    self.simplified
  end
  
  def wiktionary_url
    "http://en.wiktionary.org/wiki/#{self.simplified}#Mandarin"
  end
  
  def has_radicals(first, second)
    Radical.where("id = ? OR id IN (?)", first.id, first.synonyms).each do |first_radical|
      if(self.radicals.to_a.subtract_once(first_radical).count == self.radicals.count - 1)
        Radical.where("id = ? OR id IN (?)", second.id, second.synonyms).each do |second_radical|
          return true if self.radicals.to_a.subtract_once(first_radical).include?(second_radical)
        end
      end
    end
    return false
  end
  
  def zidian_word_entries(max)
    entries = Zidian.find(self.simplified)
    entries.reject{|entry|
      entry.english.count == 0                  ||
      entry.simplified.split(//).count > 6      ||
      entry.english.join.include?("variant of") ||
      entry.english.join.include?("surname")    ||
      !entry.simplified.split(//).include?(self.simplified)       
    }.sort{|a,b| a.simplified.length <=> b.simplified.length}.slice(0, max)  
  end
  
  def self.single_radicals
    # Radical.where("first_screen = ? OR second_screen = ?", true, true).collect{|r| r.characters.keep_if{|c| c.radicals.count == 1} }
    
    Radical.all.to_a.collect{|r| r.characters.keep_if{|c| c.radicals.count == 1} }.flatten.uniq
  end
  
  private
  
  def touch_self(radical)
    self.touch
  end
end