class Radical < ActiveRecord::Base
  validates_uniqueness_of :simplified
  validates :position, :inclusion => 1..214
end
