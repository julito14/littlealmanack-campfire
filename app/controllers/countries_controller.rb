class CountriesController < ApplicationController
  def show
    @country = Nearby.new.country(params[:id].to_s.upcase) or raise ActiveRecord::RecordNotFound
  end
end
