class RadicalsController < ApplicationController
  before_action :set_radical, only: [:show, :edit, :update, :destroy]

  # GET /radicals
  # GET /radicals.json
  def index
    @radicals = Radical.all
  end

  # GET /radicals/1
  # GET /radicals/1.json
  def show
  end

  # GET /radicals/new
  def new
    @radical = Radical.new
  end

  # GET /radicals/1/edit
  def edit
  end

  # POST /radicals
  # POST /radicals.json
  def create
    @radical = Radical.new(radical_params)

    respond_to do |format|
      if @radical.save
        format.html { redirect_to @radical, notice: 'Radical was successfully created.' }
        format.json { render action: 'show', status: :created, location: @radical }
      else
        format.html { render action: 'new' }
        format.json { render json: @radical.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /radicals/1
  # PATCH/PUT /radicals/1.json
  def update
    respond_to do |format|
      if @radical.update(radical_params)
        format.html { redirect_to @radical, notice: 'Radical was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @radical.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /radicals/1
  # DELETE /radicals/1.json
  def destroy
    @radical.destroy
    respond_to do |format|
      format.html { redirect_to radicals_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_radical
      @radical = Radical.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def radical_params
      params.require(:radical).permit(:position, :simplified, :variant)
    end
end
