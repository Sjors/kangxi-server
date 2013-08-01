class Radical < ActiveRecord::Base
  # validates_uniqueness_of :simplified  # Exception: 罒 belongs to radical 112 and 109
  validates_length_of :simplified, :is => 1
  validates :position, :inclusion => 1..214
  validates_uniqueness_of :position, :unless => :variant, :message => "has already been taken. Is this a variant?"
end
