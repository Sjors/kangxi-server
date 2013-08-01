class VisitorsController < ApplicationController
  # load_and_authorize_resource

  def new
    redirect_to radicals_path unless user_signed_in?
  end

end
