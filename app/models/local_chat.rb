# A chat for members who live near each other, one per area: "📍 Mumbai area". It starts itself
# once two members live within 50 km, and keeps itself up to date: members who pick a city nearby
# join, with a hello from the club, and those who move away leave. It's only for the people who
# live there, plus administrators, who can open any of them; everyone else can DM a member from
# their profile.
module LocalChat
  RADIUS_KM = Nearby::RADIUS_KM
  HOST_NAME = "Little Almanack"

  extend self

  # The chat for the area around the city, if one has been started.
  def find(city)
    nearest_within_reach(city).first
  end

  def open!(city, by:)
    room = find(city) || start!(city)
    room.memberships.grant_to(by) unless room.users.include?(by)
    room
  end

  # A member's city changed: into the chats around the new city (starting one if they're the
  # second member around), out of the ones far from it. Administrators stay in any they've opened.
  def follow(user)
    nearby = user.city ? nearest_within_reach(user.city) : []

    unless user.administrator?
      user.rooms.locals.where.not(id: nearby.map(&:id)).each { |room| room.memberships.revoke_from(user) }
    end

    if nearby.any?
      (nearby - user.rooms.locals.to_a).each { |room| welcome user, into: room }
    elsif user.city && neighbours?(user.city)
      start!(user.city).then { |room| welcome user, into: room }
    end
  end

  # Starts the chats for areas that already have two or more members. Run once when local chats
  # arrived; after that they start themselves.
  def start_everywhere
    members = User.active.without_bots.where.not(city_id: nil).includes(:city).sort_by { |member| -member.city.population }

    members.each_with_object([]) do |member, started|
      started << start!(member.city) if find(member.city).nil? && neighbours?(member.city)
    end
  end

  # The club's own account, which owns the chats and posts their notes, with the club's book as
  # its picture.
  def host
    bot = User.active_bots.find_by(name: HOST_NAME) || User.create_bot!(name: HOST_NAME)
    bot.tap { give_host_its_picture(bot) unless bot.avatar.attached? }
  end

  private
    def nearest_within_reach(city)
      Rooms::Closed.locals.includes(:city).map { |room| [ room, room.city.distance_to(city) ] }
        .select { |_, km| km <= RADIUS_KM }.sort_by(&:last).map(&:first)
    end

    # Named after the biggest city among the members around, so Mumbai and Ulhasnagar share one.
    def start!(city)
      anchor = Nearby.new.around(city).map { |member, _| member.city }.max_by(&:population) || city
      locals = Nearby.new.around(anchor).map(&:first)

      Rooms::Closed.create_for({ name: "📍 #{anchor.name} area", city: anchor, creator: host }, users: locals).tap do |room|
        show_in_sidebars room, of: locals
        say room, "📍 This is the chat for members within #{RADIUS_KM} km of #{anchor.name}. " \
          "Anyone who adds a city nearby joins automatically."
      end
    end

    def neighbours?(city)
      Nearby.new.around(city).many?
    end

    def welcome(user, into:)
      unless into.users.include?(user)
        into.memberships.grant_to(user)
        show_in_sidebars into, of: [ user ]
      end

      say into, hello_for(user) unless greeted_recently?(user, room: into)
    end

    # Fits someone moving in as well as someone visiting
    def hello_for(user)
      "👋 #{user.name} is now in #{user.city.name}. Say hi!"
    end

    # Someone who switches city away and back (or fixes a wrong pick) isn't announced twice.
    def greeted_recently?(user, room:)
      room.messages.where(creator: host, created_at: 1.day.ago..)
        .any? { |message| message.plain_text_body.start_with?("👋 #{user.name} ") }
    end

    def give_host_its_picture(bot)
      bot.avatar.attach io: File.open(Rails.root.join("app/assets/images/little-almanack-avatar.png")),
        filename: "little-almanack.png", content_type: "image/png"
    end

    def say(room, text)
      room.messages.create!(creator: host, body: text).broadcast_create
    end

    def show_in_sidebars(room, of:)
      of.each do |user|
        Turbo::StreamsChannel.broadcast_append_to user, :rooms, target: "shared_rooms",
          partial: "users/sidebars/rooms/shared", locals: { room: room, unread: true }
      end
    end
end
