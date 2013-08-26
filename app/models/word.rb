require 'open-uri'
class Word < ActiveRecord::Base
  has_and_belongs_to_many :characters
  
  validates_uniqueness_of :simplified
  
  def wiktionary_url
    "http://en.wiktionary.org/wiki/#{self.simplified}#Mandarin"
  end
  
  def pronunciation_url
    
    character_param = URI::encode self.simplified
    
    resource = open("http://apifree.forvo.com/key/f12f9942d441e46720bcf6543c2d5baa/format/json/action/word-pronunciations/word/#{ character_param }/language/zh/limit/1/order/rate-desc")
    return nil unless resource
    json = JSON.parse(resource.read)
    return nil unless json && json["items"] && json["items"].count > 0
    return json["items"].first["pathmp3"]
  end
  
  def pinyin
    PinYin.of_string(self.simplified, :unicode).join(" ")
  end
  
  def self.english_given_zidian_entry(zidian)
    zidian.english.slice(0,3).collect{|meaning| meaning.slice(0,25)}
  end
end
