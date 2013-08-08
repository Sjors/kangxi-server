class LookupController < ApplicationController
  # load_and_authorize_resource
  
  def index 
    @radicals = Radical.where(first_screen: true)
  end
  
  def radical
    @radical = Radical.find(params[:id])
    @characters = @radical.characters
  end
end