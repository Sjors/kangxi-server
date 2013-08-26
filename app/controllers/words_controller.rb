class WordsController < ApplicationController
  before_action :set_word, only: [:pronunciation]
  
  def pronunciation
    url = @word.pronunciation_url
    if url.nil?
      render :nothing => true, :status => 404
    else
      redirect_to url
    end
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_word
      @word = Word.find(params[:id])
    end
end
