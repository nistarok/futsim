#!/usr/bin/env ruby

round = Round.first
room = round.room
clubs = room.clubs.limit(2)

if clubs.count >= 2
  puts "Testing match creation..."

  # Criar partida
  match = Match.create!(
    round: round,
    home_club: clubs.first,
    away_club: clubs.last,
    status: "scheduled",
    match_date: DateTime.current
  )

  puts "Match created: #{match.display_result}"
  puts "Status: #{match.status}"

  # Simular partida
  match.simulate!
  puts "After simulation: #{match.display_result}"
  puts "Status: #{match.status}"
  puts "Winner: #{match.winner&.name || 'Draw'}"
  puts "Points for #{match.home_club.name}: #{match.points_for_club(match.home_club)}"
  puts "Points for #{match.away_club.name}: #{match.points_for_club(match.away_club)}"
else
  puts "Need at least 2 clubs for testing"
end