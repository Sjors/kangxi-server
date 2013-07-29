class Character < ActiveRecord::Base
  validates_uniqueness_of :simplified
end
