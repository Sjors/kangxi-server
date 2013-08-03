class Character < ActiveRecord::Base
  validates_uniqueness_of :simplified
  validates_length_of :simplified, :is => 1
  
  has_and_belongs_to_many :radicals
  
  def remove_radical(radical, count = 1)
    current_radical_count = self.radicals.where(id: radical.id).count
    self.radicals.delete(radical)
    (current_radical_count - count).times { self.radicals << radical }
  end
end
