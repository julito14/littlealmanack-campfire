namespace :local_chats do
  desc "Start the chats for areas that already have two or more members (once; after that they start themselves)"
  task start: :environment do
    LocalChat.start_everywhere.each do |room|
      puts "#{room.name.ljust(30)} #{room.users.count} members"
    end
  end
end
