class LookupController < ApplicationController
  # load_and_authorize_resource
  
  def index 
    @radicals = Radical.where(first_screen: true)
  end
  
  def first_radical
    @radical = Radical.find(params[:id])
    @radicals = Radical.where("id in (?)", @radical.radicals)
    # @characters = @radical.characters
  end
  
  def second_radical
    @first_radical = Radical.find(params[:first_id])
    @second_radical = Radical.find(params[:second_id])
    
    # @characters = Character.joins(:radicals).where("radicals.id = ?", @first_radical.id).where("radicals.id = ?", @second_radical.id)
    
    @characters = @first_radical.characters.keep_if{|c| c.radicals.include?(@second_radical)}
    
  end
end