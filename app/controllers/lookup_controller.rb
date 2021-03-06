class LookupController < ApplicationController
  # load_and_authorize_resource
  
  def index 
    @radicals = Radical.where(first_screen: true)
  end
  
  def index_more
    @radicals = Radical.where(second_screen: true)
  end
  
  def index_more_more
    @radicals = Radical.where(third_screen: true)
  end
  
  def index_more_more_characters
    @characters = Character.where(fourth_screen: true)
  end
  
  def first_radical
    @radical = Radical.find(params[:id])
    
    if @radical.first_screen || @radical.second_screen
      @radicals = Radical.where("id in (?)", @radical.radicals)
    else
      @characters = @radical.third_screen_potential_characters
    end
  end
  
  def first_radical_more
    @radical = Radical.find(params[:id])
    @radicals = Radical.where("id in (?)", @radical.secondary_radicals)
  end
  
  def first_radical_more_characters
    @radical = Radical.find(params[:id])
    
    @characters = Rails.cache.fetch(@radical.cache_key) {
      chars = []
    
      Radical.where("id in (?)", @radical.tertiary_radicals).each do |second_radical|      
        chars << @radical.with_synonym_characters.keep_if{|character| character.has_radicals(@radical, second_radical)}
      end
    
      chars.flatten.uniq.to_a.slice(0,35)
    }
  end
  
  def second_radical
    @first_radical = Radical.find(params[:first_id])
    @second_radical = Radical.find(params[:second_id])
    
    @characters = Rails.cache.fetch( "Characters" + @first_radical.cache_key + @second_radical.cache_key ) {
      if @first_radical.first_screen
        @first_radical.with_synonym_characters.where(first_screen: true).keep_if{|c| c.has_radicals(@first_radical, @second_radical)}
      else # Second screen characters:
        @first_radical.with_synonym_characters.where(second_screen: true).keep_if{|c| c.has_radicals(@first_radical, @second_radical)} 
      end
    }    

    
  end

end