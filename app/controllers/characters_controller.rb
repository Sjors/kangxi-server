class CharactersController < ApplicationController
  load_and_authorize_resource
  before_action :set_character, only: [:show, :edit, :update, :destroy, :add_radical, :remove_radical]

  # GET /characters
  # GET /characters.json
  def index
    if user_signed_in? || Rails.env == "test"
      @characters = Character.all.order("level asc, characters.id asc").page(params[:page])
    else
      @characters = Character.all.includes(:radicals).where("radicals.id IS NOT NULL").order("level asc, characters.id asc").page(params[:page])
    end
  end

  # GET /characters/1
  # GET /characters/1.json
  def show
    if user_signed_in?
      @radicals = Radical.where(variant: false).order(position: :asc)
    end
  end

  # GET /characters/new
  def new
    @character = Character.new
  end

  # GET /characters/1/edit
  def edit
  end

  # POST /characters
  # POST /characters.json
  def create
    @character = Character.new(character_params)

    respond_to do |format|
      if @character.save
        format.html { redirect_to new_character_path, notice: 'Successfully added ' + @character.simplified + '.' }
        format.json { render action: 'show', status: :created, location: @character }
      else
        format.html { render action: 'new' }
        format.json { render json: @character.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /characters/1
  # PATCH/PUT /characters/1.json
  def update
    respond_to do |format|
      if @character.update(character_params)
        format.html { redirect_to @character, notice: 'Character was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @character.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /characters/1
  # DELETE /characters/1.json
  def destroy
    @character.destroy
    respond_to do |format|
      format.html { redirect_to characters_url }
      format.json { head :no_content }
    end
  end
  
  def add_radical
    respond_to do |format|
      @radical = Radical.find(params[:radical])
      
      unless @radical.present?
        format.html { redirect_to @character, error: 'No radical found to add to character.' }
      end
      
      if @character.radicals << @radical
        format.html { redirect_to @character, notice: "#{ @radical.simplified } succesfully added." }
      else
        format.html { redirect_to @character, error: "Unable to add #{ @radical.simplified  }."  }
      end
    end
  end
  
  def remove_radical
    respond_to do |format|
      @radical = Radical.find(params[:radical])
      
      unless @radical.present?
        format.html { redirect_to @character, error: 'No radical found to remove from character.' }
      end
      
      if @character.remove_radical(@radical)
        format.html { redirect_to @character, notice: "#{ @radical.simplified } succesfully removed." }
      else
        format.html { redirect_to @character, error: "Unable to remove #{ @radical.simplified  }."  }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_character
      @character = Character.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def character_params
      params.require(:character).permit(:simplified)
    end
end
