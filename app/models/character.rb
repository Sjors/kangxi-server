class Character < ActiveRecord::Base
  validates_uniqueness_of :simplified
  validates_length_of :simplified, :is => 1
  
  validates_presence_of :level
  validates :level, :inclusion => 1..6 
  
  has_and_belongs_to_many :radicals
  
  self.per_page = 100
  
  # default_scope -> { order("level asc, characters.id asc") }
  
  def remove_radical(radical, count = 1)
    current_radical_count = self.radicals.where(id: radical.id).count
    self.radicals.delete(radical)
    (current_radical_count - count).times { self.radicals << radical }
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
end
