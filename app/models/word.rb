require 'open-uri'
class Word < ActiveRecord::Base
  has_and_belongs_to_many :characters
  
  def wiktionary_url
    "http://en.wiktionary.org/wiki/#{self.simplified}#Mandarin"
  end
  
  def forvo_audio_html
    
    character_param = URI::encode self.simplified
    
    resource = open("http://apifree.forvo.com/key/f12f9942d441e46720bcf6543c2d5baa/format/json/action/word-pronunciations/word/#{ character_param }/language/zh/limit/1")
    return "<audio controls />".html_safe unless resource
    json = JSON.parse(resource.read)
    return "<audio controls />".html_safe unless json && json["items"] && json["items"].count > 0
    return "<audio controls preload='none'><source src='#{ json["items"].first["pathmp3"] }' type='audio/mpeg'></audio>".html_safe
  end
  
  def pinyin
    PinYin.of_string(self.simplified, :unicode).join(" ")
  end
end
