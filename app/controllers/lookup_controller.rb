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
    @characters = []
    
    Radical.where("id in (?)", @radical.tertiary_radicals).each do |second_radical|      
      @characters << @radical.characters.keep_if{|character| character.has_radicals(@radical, second_radical)}
    end
    
    @characters.flatten!.uniq!.to_a.slice(0,35)
  end
  
  def second_radical
    @first_radical = Radical.find(params[:first_id])
    @second_radical = Radical.find(params[:second_id])
    
    if @first_radical.first_screen
      @characters = @first_radical.characters.where(first_screen: true).keep_if{|c| c.has_radicals(@first_radical, @second_radical)}
    else # Second screen characters:
      @characters = @first_radical.characters.where(second_screen: true).keep_if{|c| c.has_radicals(@first_radical, @second_radical)} 
    end
    
  end

end