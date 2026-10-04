namespace :rooms do
  desc 'Put the sidebar rooms in a given order: ORDER="👋 Hi|📚 Books|..." (names as shown; unlisted rooms follow alphabetically)'
  task order: :environment do
    names = ENV.fetch("ORDER").split("|").map(&:strip)
    rooms = names.map { |name| Room.without_directs.find_by(name: name) or abort "No room named #{name.inspect}" }

    Room.transaction do
      Room.without_directs.update_all(position: nil)
      rooms.each.with_index(1) { |room, position| room.update_columns(position: position) }
    end

    rooms.each.with_index(1) { |room, position| puts "#{position}. #{room.name}" }
  end
end
