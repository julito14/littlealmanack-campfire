# Opens the chat for the area around a city, starting it if nobody has yet. Only for members who
# live within 50 km, and administrators.
class LocalChatsController < ApplicationController
  def create
    city = City.find(params[:city_id])

    if Current.user.administrator? || Nearby.new.around(city).any? { |member, _| member == Current.user }
      redirect_to room_url(LocalChat.open!(city, by: Current.user))
    else
      head :forbidden
    end
  end
end
