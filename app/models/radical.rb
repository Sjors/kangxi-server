class Radical < ActiveRecord::Base
  # validates_uniqueness_of :simplified  # Exception: 罒 belongs to radical 112 and 109
  validates_length_of :simplified, :is => 1
  validates :position, :inclusion => 1..214
  validates_uniqueness_of :position, :scope => :variant, :unless => :variant, :message => "has already been taken. Is this a variant?"

  has_and_belongs_to_many :characters
  
  def rank
    tally = self.position * 10
    
    if self.variant
      tally = tally + Radical.where(position: self.position).order(variant: :asc).collect{|v| v.id}.find_index(self.id)
    end
    
    return tally
  end
  
  def with_synonym_characters
    return self.characters.group("characters.id") if self.synonyms.count == 0
    Character.joins(:radicals).where("level = 1 OR level = 2").where("radicals.id = ? OR radicals.id IN (?)", self.id, self.synonyms).group("characters.id")
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
  
  def matches(warn)
    characters = []
    Radical.where("id in (?)", self.radicals).each do |second_radical|      
      matches = self.characters.keep_if{|character| character.has_radicals(self, second_radical)}
      characters << matches.to_a.slice(0,50)
      if matches.count > 50 && warn 
        puts "#{ self } #{ second_radical } matches #{ matches.count } characters, 50 allowed."
      end
    end
    
    characters.flatten.uniq
  end
  
  def tooltip
    tips = []
    if self.synonyms.length > 0
      tips << "Also " + Radical.where("id in (?)", self.synonyms).collect{|r| r.to_s}.join(" ")
    end
    
    if self.do_not_confuse && self.do_not_confuse.length > 0
      tips << "Not " + Radical.where("id in (?)", self.do_not_confuse).collect{|r| r.to_s}.join(" ")
    end
    
    tips.join("\n")
  end
  
  def self.make_synonyms(primary, synonyms)
    first = Radical.find_by(simplified: primary) 
    second = synonyms.collect {| synonym | Radical.find_by(simplified: synonym) }
    
    first.update synonyms: second.collect{|s| s.id}
    second.each do |s|
      s.update is_synonym: true
    end
  end
  
  ##########
  # Export #
  ##########
  
  def self.export_radicals_characters(f)
    res = self.where(is_synonym: false).where("frequency < ?", 100).order(frequency: :desc).limit(100).collect{|first_radical|
      {
        simplified: first_radical.simplified,
        rank: -first_radical.frequency,
        demo: first_radical.demo,
        second_radicals: Radical.where("id in (?)", first_radical.radicals).collect{|second_radical|
          {
            simplified: second_radical.simplified,
            rank: -second_radical.frequency, # TODO: frequency given first radical
            demo: second_radical.demo && first_radical.with_synonym_characters.keep_if{|c| c.demo && c.has_radicals(first_radical, second_radical)}.count > 0,
            characters: first_radical.with_synonym_characters.keep_if{|c| c.has_radicals(first_radical, second_radical)}.collect {|character|
              {
                simplified: character.simplified,
                rank: character.rank,
                demo: character.demo
              }
            } 
          }         
        }
      }
    }
    
    f << res.to_json
  end
  
  def self.export_characters_words(f)
    res = Character.all.keep_if{|c| c.radicals.count > 0}.collect{|c|
      {
        simplified: c.simplified,
        words: c.words.collect{|w|
          {
            simplified: w.simplified,
            english: w.english.join('; ') 
            # english: w.english.collect{| e | e.gsub("\"","\\\"")}.join('; ') 
          }
        }
      }
    }  
    f << res.to_json  
  end
  
  def self.export_synonyms(f)
    res = Radical.all.keep_if{|r|  r.synonyms.count > 0 && r.simplified != "阝" && r.simplified != "罒"}.collect{|r|
      {
        simplified: r.simplified,
        synonyms: Radical.where("id in (?)", r.synonyms).collect{|s| s.simplified}.join(" ")
        # synonyms: Radical.where("id in (?)", r.synonyms).collect{|s|
        #   {
        #     simplified: s.simplified
        #   }
        # }
      }
    }
    f << res.to_json  
    
  end
end
