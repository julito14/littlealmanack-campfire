class Rooms::DirectsController < RoomsController
  before_action :set_room, only: %i[ edit destroy ]
  def new
    @room = Rooms::Direct.new
  end

  # The DM reaches the other people's lists with its first message (Message::Broadcasts), not here:
  # tapping someone shouldn't put an empty conversation in front of them.
  def create
    room = Rooms::Direct.find_or_create_for(selected_users)

    redirect_to room_url(room)
  end

  def edit
  end

  private
    def selected_users
      User.where(id: selected_users_ids.including(Current.user.id))
    end

    def selected_users_ids
      params.fetch(:user_ids, [])
    end

    # All users in a direct room can administer it. Only direct rooms, though: this
    # relaxation is why room_scope below has to keep every other type out of reach.
    def ensure_can_administer
      true
    end

    def room_scope
      Current.user.rooms.directs
    end
end
