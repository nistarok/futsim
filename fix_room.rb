room = Room.find(4)
PlayerPoolGeneratorService.new(room).generate_default_clubs!
puts "Generated clubs for room #{room.name}"