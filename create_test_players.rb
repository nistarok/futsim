#!/usr/bin/env ruby

# Simple script to create test players
club = Club.first

if club.nil?
  puts "No club found"
  exit
end

puts "Creating players for: #{club.name}"

# Create simple test players
10.times do |i|
  Player.create!(
    name: "Jogador #{i + 1}",
    nationality: "BRA",
    position: ["GK", "CB", "LB", "RB", "CM", "ST"].sample,
    age: rand(18..35),
    strength: rand(40..90),
    stamina: rand(40..90),
    speed: rand(40..90),
    attack: rand(40..90),
    defense: rand(40..90),
    passing: rand(40..90),
    overall: rand(60..85),
    market_value: rand(100_000..1_000_000),
    salary: rand(10_000..50_000),
    club: club
  )
end

puts "Players created: #{Player.count}"