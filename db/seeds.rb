# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting seeds..."

# Create invited user for testing
if Rails.env.development?
  user = User.find_by(email: 'udo.schmidt.jr@gmail.com')
  if user.nil?
    user = User.invite!('udo.schmidt.jr@gmail.com')
    puts "✅ Created invited user: #{user.email}"
  else
    status = user.invited? ? 'invited' : 'active'
    puts "📧 User already exists: #{user.email} (status: #{status})"
  end
end

# Create Divisions (Brazilian Football System)
puts "\n🏆 Creating divisions..."

divisions_data = [
  { name: "Série A", level: 1, description: "Primeira divisão do futebol brasileiro" },
  { name: "Série B", level: 2, description: "Segunda divisão do futebol brasileiro" },
  { name: "Série C", level: 3, description: "Terceira divisão do futebol brasileiro" },
  { name: "Série D", level: 4, description: "Quarta divisão do futebol brasileiro" },
  { name: "Estadual", level: 5, description: "Campeonatos estaduais" }
]

divisions_data.each do |div_data|
  division = Division.find_or_create_by(name: div_data[:name]) do |d|
    d.level = div_data[:level]
    d.description = div_data[:description]
  end
  puts "📊 Division: #{division.name} (Level #{division.level})"
end

puts "\n✅ Seeds completed successfully!"
puts "📊 Total divisions: #{Division.count}"
puts "👤 Total users: #{User.count}"
puts "\n📝 Note: Clubs will be created when users create rooms and choose clubs"
