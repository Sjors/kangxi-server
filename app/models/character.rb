class Character < ActiveRecord::Base
  validates_uniqueness_of :simplified
  validates_length_of :simplified, :is => 1
end
