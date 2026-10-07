module WelcomeNotesHelper
  # "👋 Hi" → "Hi": the note has its own 👋 in front of the line
  def welcome_room_name(room)
    room.name.to_s.sub(/\A\p{Extended_Pictographic}️?\s*/, "")
  end
end
