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

def create_squad_for_club(club)
  # Brazilian player names
  first_names = %w[João Pedro Lucas Gabriel Rafael Miguel Arthur Davi Bernardo Matheus Enzo Felipe Lorenzo Benjamin Nicolas Guilherme Samuel Henrique Gustavo Vicente]
  last_names = %w[Silva Santos Oliveira Costa Souza Rodrigues Ferreira Alves Pereira Lima Gomes Ribeiro Carvalho Martins Araújo Melo Barbosa Cardoso Nascimento Dias]

  positions_config = {
    'GK' => { count: 3, overall_range: 65..85 },
    'CB' => { count: 4, overall_range: 70..88 },
    'LB' => { count: 2, overall_range: 68..85 },
    'RB' => { count: 2, overall_range: 68..85 },
    'CDM' => { count: 2, overall_range: 72..87 },
    'CM' => { count: 4, overall_range: 70..89 },
    'CAM' => { count: 2, overall_range: 73..90 },
    'LM' => { count: 1, overall_range: 71..86 },
    'RM' => { count: 1, overall_range: 71..86 },
    'LW' => { count: 2, overall_range: 74..90 },
    'RW' => { count: 2, overall_range: 74..90 },
    'ST' => { count: 3, overall_range: 75..92 }
  }

  positions_config.each do |position, config|
    config[:count].times do
      overall = rand(config[:overall_range])
      age = rand(18..35)

      # Calculate market value and salary based on overall and age
      base_value = overall ** 2 * 10_000
      age_factor = case age
                   when 18..21 then 1.5
                   when 22..26 then 1.8
                   when 27..30 then 1.3
                   when 31..35 then 0.7
                   else 0.5
                   end

      market_value = (base_value * age_factor * rand(0.7..1.3)).round
      salary = (market_value * 0.02 * rand(0.8..1.5)).round

      Player.create!(
        name: "#{first_names.sample} #{last_names.sample}",
        nationality: "BRA",
        position: position,
        age: age,
        strength: rand(40..90),
        stamina: rand(40..90),
        speed: rand(40..90),
        attack: rand(40..90),
        defense: rand(40..90),
        passing: rand(40..90),
        overall: overall,
        market_value: market_value,
        salary: salary,
        club: club
      )
    end
  end
end

# Create sample room and clubs for testing
if Rails.env.development?
  puts "\n🏠 Creating sample room with clubs..."

  # Create a test room if it doesn't exist
  room = Room.find_or_create_by(name: "Liga Brasileira Test") do |r|
    r.user_id = user&.id
    r.is_multiplayer = true
    r.max_players = 16
    r.current_players = 1
    r.description = "Sala de teste com clubes brasileiros"
    r.status = "active"
  end

  serie_a = Division.find_by(name: "Série A")

  if serie_a && Club.where(room: room).count == 0
    # Brazilian clubs for Serie A
    clubs_data = [
      { name: "Flamengo", city: "Rio de Janeiro", founded: 1895, stadium: "Maracanã", capacity: 78838 },
      { name: "Corinthians", city: "São Paulo", founded: 1910, stadium: "Neo Química Arena", capacity: 49205 },
      { name: "São Paulo", city: "São Paulo", founded: 1930, stadium: "Morumbi", capacity: 67428 },
      { name: "Palmeiras", city: "São Paulo", founded: 1914, stadium: "Allianz Parque", capacity: 43713 },
      { name: "Santos", city: "Santos", founded: 1912, stadium: "Vila Belmiro", capacity: 16068 },
      { name: "Vasco da Gama", city: "Rio de Janeiro", founded: 1898, stadium: "São Januário", capacity: 21880 },
      { name: "Botafogo", city: "Rio de Janeiro", founded: 1904, stadium: "Nilton Santos", capacity: 46831 },
      { name: "Fluminense", city: "Rio de Janeiro", founded: 1902, stadium: "Maracanã", capacity: 78838 },
      { name: "Grêmio", city: "Porto Alegre", founded: 1903, stadium: "Arena do Grêmio", capacity: 55662 },
      { name: "Internacional", city: "Porto Alegre", founded: 1909, stadium: "Beira-Rio", capacity: 50128 },
      { name: "Atlético Mineiro", city: "Belo Horizonte", founded: 1908, stadium: "Arena MRV", capacity: 46000 },
      { name: "Cruzeiro", city: "Belo Horizonte", founded: 1921, stadium: "Mineirão", capacity: 61846 },
      { name: "Bahia", city: "Salvador", founded: 1931, stadium: "Arena Fonte Nova", capacity: 50025 },
      { name: "Vitória", city: "Salvador", founded: 1899, stadium: "Barradão", capacity: 35632 },
      { name: "Fortaleza", city: "Fortaleza", founded: 1918, stadium: "Castelão", capacity: 63903 },
      { name: "Ceará", city: "Fortaleza", founded: 1914, stadium: "Castelão", capacity: 63903 },
      { name: "Sport", city: "Recife", founded: 1905, stadium: "Ilha do Retiro", capacity: 29472 },
      { name: "Náutico", city: "Recife", founded: 1901, stadium: "Arena Pernambuco", capacity: 44300 },
      { name: "Guarani", city: "Campinas", founded: 1911, stadium: "Brinco de Ouro", capacity: 29130 },
      { name: "Ponte Preta", city: "Campinas", founded: 1900, stadium: "Moisés Lucarelli", capacity: 19722 }
    ]

    clubs_data.each_with_index do |club_data, index|
      # Only assign first club to test user, rest are NPCs
      user_assignment = (index == 0 && user) ? user.id : nil

      club = Club.create!(
        name: club_data[:name],
        city: club_data[:city],
        founded_year: club_data[:founded],
        stadium_name: club_data[:stadium],
        stadium_capacity: club_data[:capacity],
        budget: rand(50_000_000..200_000_000),
        division: serie_a,
        room: room,
        user_id: user_assignment
      )

      puts "⚽ Club: #{club.name} (#{club.npc? ? 'NPC' : 'User controlled'})"

      # Create players for each club
      create_squad_for_club(club)
    end
  end
end

puts "\n✅ Seeds completed successfully!"
puts "📊 Total divisions: #{Division.count}"
puts "👤 Total users: #{User.count}"
puts "🏠 Total rooms: #{Room.count}"
puts "⚽ Total clubs: #{Club.count}"
puts "👥 Total players: #{Player.count}"
puts "\n📝 Note: Sample room 'Liga Brasileira Test' created with 20 clubs and full squads"

def create_squad_for_club(club)
  # Brazilian player names
  first_names = %w[João Pedro Lucas Gabriel Rafael Miguel Arthur Davi Bernardo Matheus Enzo Felipe Lorenzo Benjamin Nicolas Guilherme Samuel Henrique Gustavo Vicente]
  last_names = %w[Silva Santos Oliveira Costa Souza Rodrigues Ferreira Alves Pereira Lima Gomes Ribeiro Carvalho Martins Araújo Melo Barbosa Cardoso Nascimento Dias]

  positions_config = {
    'GK' => { count: 3, overall_range: 65..85 },
    'CB' => { count: 4, overall_range: 70..88 },
    'LB' => { count: 2, overall_range: 68..85 },
    'RB' => { count: 2, overall_range: 68..85 },
    'CDM' => { count: 2, overall_range: 72..87 },
    'CM' => { count: 4, overall_range: 70..89 },
    'CAM' => { count: 2, overall_range: 73..90 },
    'LM' => { count: 1, overall_range: 71..86 },
    'RM' => { count: 1, overall_range: 71..86 },
    'LW' => { count: 2, overall_range: 74..90 },
    'RW' => { count: 2, overall_range: 74..90 },
    'ST' => { count: 3, overall_range: 75..92 }
  }

  positions_config.each do |position, config|
    config[:count].times do
      overall = rand(config[:overall_range])
      age = rand(18..35)

      # Calculate market value and salary based on overall and age
      base_value = overall ** 2 * 10_000
      age_factor = case age
                   when 18..21 then 1.5
                   when 22..26 then 1.8
                   when 27..30 then 1.3
                   when 31..35 then 0.7
                   else 0.5
                   end

      market_value = (base_value * age_factor * rand(0.7..1.3)).round
      salary = (market_value * 0.02 * rand(0.8..1.5)).round

      Player.create!(
        name: "#{first_names.sample} #{last_names.sample}",
        nationality: "BRA",
        position: position,
        age: age,
        strength: rand(40..90),
        stamina: rand(40..90),
        speed: rand(40..90),
        attack: rand(40..90),
        defense: rand(40..90),
        passing: rand(40..90),
        overall: overall,
        market_value: market_value,
        salary: salary,
        club: club
      )
    end
  end
end
