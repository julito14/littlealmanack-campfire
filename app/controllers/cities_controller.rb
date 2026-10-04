class CitiesController < ApplicationController
  # The search backs the city picker on the sign-up page too, before anyone has an account.
  allow_unauthenticated_access only: :index
  rate_limit to: 60, within: 1.minute, only: :index, with: -> { head :too_many_requests }

  def index
    cities = City.search(params[:q])

    render json: cities.map { |city| { id: city.id, name: city.name, label: city.label, place: city.place, alias: city.alias_matching(params[:q]) } }
  end

  # Everyone within 50 km of the city.
  def show
    @city = City.find(params[:id])
    @nearby = Nearby.new.around(@city)
  end
end
