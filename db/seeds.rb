# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Starting seeds..."

# Create invited user for testing
if Rails.env.development?
  user = User.find_by(email: 'udo.schmidt.jr@gmail.com')
  if user.nil?
    user = User.invite!('udo.schmidt.jr@gmail.com')
    puts "Created invited user: #{user.email}"
  else
    status = user.invited? ? 'invited' : 'active'
    puts "User already exists: #{user.email} (status: #{status})"
  end
end

# Create Divisions (Brazilian Football System)
puts "\nCreating divisions..."

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
  puts "Division: #{division.name} (Level #{division.level})"
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

# Create comprehensive club database (16 clubs per division = 80 total clubs)
puts "\nCreating comprehensive club database..."

# All Brazilian clubs data (16 per division)
all_clubs_data = {
  1 => [ # Série A (top tier)
    { name: "Flamengo", city: "Rio de Janeiro", founded: 1895, stadium: "Maracanã", capacity: 78838 },
    { name: "Palmeiras", city: "São Paulo", founded: 1914, stadium: "Allianz Parque", capacity: 43713 },
    { name: "São Paulo", city: "São Paulo", founded: 1930, stadium: "Morumbi", capacity: 67428 },
    { name: "Corinthians", city: "São Paulo", founded: 1910, stadium: "Neo Química Arena", capacity: 49205 },
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
    { name: "Ceará", city: "Fortaleza", founded: 1914, stadium: "Castelão", capacity: 63903 }
  ],
  2 => [ # Série B
    { name: "Sport", city: "Recife", founded: 1905, stadium: "Ilha do Retiro", capacity: 29472 },
    { name: "Náutico", city: "Recife", founded: 1901, stadium: "Arena Pernambuco", capacity: 44300 },
    { name: "Guarani", city: "Campinas", founded: 1911, stadium: "Brinco de Ouro", capacity: 29130 },
    { name: "Ponte Preta", city: "Campinas", founded: 1900, stadium: "Moisés Lucarelli", capacity: 19722 },
    { name: "América-MG", city: "Belo Horizonte", founded: 1912, stadium: "Arena Independência", capacity: 23018 },
    { name: "Vila Nova", city: "Goiânia", founded: 1943, stadium: "Estádio Onésio Brasileiro Alvarenga", capacity: 11788 },
    { name: "Goiás", city: "Goiânia", founded: 1943, stadium: "Estádio da Serrinha", capacity: 14450 },
    { name: "CRB", city: "Maceió", founded: 1912, stadium: "Estádio Rei Pelé", capacity: 17000 },
    { name: "CSA", city: "Maceió", founded: 1913, stadium: "Estádio Rei Pelé", capacity: 17000 },
    { name: "Sampaio Corrêa", city: "São Luís", founded: 1923, stadium: "Estádio Castelão", capacity: 40000 },
    { name: "Operário-PR", city: "Ponta Grossa", founded: 1912, stadium: "Estádio Germano Krüger", capacity: 8000 },
    { name: "Coritiba", city: "Curitiba", founded: 1909, stadium: "Couto Pereira", capacity: 40502 },
    { name: "Chapecoense", city: "Chapecó", founded: 1973, stadium: "Arena Condá", capacity: 22600 },
    { name: "Avaí", city: "Florianópolis", founded: 1923, stadium: "Ressacada", capacity: 17800 },
    { name: "Figueirense", city: "Florianópolis", founded: 1921, stadium: "Orlando Scarpelli", capacity: 19908 },
    { name: "Juventude", city: "Caxias do Sul", founded: 1913, stadium: "Estádio Alfredo Jaconi", capacity: 23726 }
  ],
  3 => [ # Série C
    { name: "ABC", city: "Natal", founded: 1915, stadium: "Frasqueirão", capacity: 18000 },
    { name: "Confiança", city: "Aracaju", founded: 1936, stadium: "Estádio Batistão", capacity: 15000 },
    { name: "Treze", city: "Campina Grande", founded: 1925, stadium: "Estádio Presidente Vargas", capacity: 6000 },
    { name: "Campinense", city: "Campina Grande", founded: 1915, stadium: "Estádio Amigão", capacity: 35000 },
    { name: "Botafogo-PB", city: "João Pessoa", founded: 1931, stadium: "Estádio Almeidão", capacity: 40000 },
    { name: "Remo", city: "Belém", founded: 1905, stadium: "Baenão", capacity: 17250 },
    { name: "Paysandu", city: "Belém", founded: 1914, stadium: "Curuzu", capacity: 16200 },
    { name: "Manaus", city: "Manaus", founded: 2013, stadium: "Arena da Amazônia", capacity: 44310 },
    { name: "Rio Branco", city: "Rio Branco", founded: 1919, stadium: "Arena Acreana", capacity: 12000 },
    { name: "Atlético-GO", city: "Goiânia", founded: 1937, stadium: "Estádio Antônio Accioly", capacity: 12500 },
    { name: "Aparecidense", city: "Aparecida de Goiânia", founded: 1985, stadium: "Estádio Aníbal Toledo", capacity: 5000 },
    { name: "Ferroviário", city: "Fortaleza", founded: 1933, stadium: "Estádio Elzir Cabral", capacity: 6000 },
    { name: "Ypiranga", city: "Erechim", founded: 1924, stadium: "Estádio Colosso da Lagoa", capacity: 6000 },
    { name: "Volta Redonda", city: "Volta Redonda", founded: 1976, stadium: "Estádio Raulino de Oliveira", capacity: 21000 },
    { name: "Tombense", city: "Tombos", founded: 1914, stadium: "Estádio Antônio Guimarães de Almeida", capacity: 2500 },
    { name: "Mirassol", city: "Mirassol", founded: 1925, stadium: "Estádio José Maria de Campos Maia", capacity: 10000 }
  ],
  4 => [ # Série D
    { name: "Jacuipense", city: "Riachão do Jacuípe", founded: 2003, stadium: "Estádio Carneirão", capacity: 5000 },
    { name: "Atlético Alagoinense", city: "Murici", founded: 1927, stadium: "Estádio Fumeirão", capacity: 3000 },
    { name: "4 de Julho", city: "Piripiri", founded: 1996, stadium: "Estádio Albertão", capacity: 16000 },
    { name: "Moto Club", city: "São Luís", founded: 1937, stadium: "Estádio Nhozinho Santos", capacity: 18000 },
    { name: "Imperatriz", city: "Imperatriz", founded: 1962, stadium: "Estádio Frei Epifânio", capacity: 8000 },
    { name: "Atlético-AC", city: "Rio Branco", founded: 1952, stadium: "Estádio José de Melo", capacity: 8000 },
    { name: "Porto Velho", city: "Porto Velho", founded: 1945, stadium: "Estádio Aluízio Ferreira", capacity: 7000 },
    { name: "Cianorte", city: "Cianorte", founded: 2002, stadium: "Estádio Albino Turbay", capacity: 7500 },
    { name: "Maringá", city: "Maringá", founded: 2010, stadium: "Estádio Willie Davids", capacity: 16500 },
    { name: "Anápolis", city: "Anápolis", founded: 1948, stadium: "Estádio Jonas Duarte", capacity: 20000 },
    { name: "Real Brasília", city: "Brasília", founded: 2001, stadium: "Estádio Defelê", capacity: 2500 },
    { name: "Brasiliense", city: "Brasília", founded: 2000, stadium: "Estádio Serejão", capacity: 25000 },
    { name: "Boavista", city: "Saquarema", founded: 1961, stadium: "Estádio Elcyr Resende", capacity: 15000 },
    { name: "Poços de Caldas", city: "Poços de Caldas", founded: 1949, stadium: "Estádio Ronaldão", capacity: 15000 },
    { name: "Tupynambás", city: "Juiz de Fora", founded: 1912, stadium: "Estádio Radialista Mário Helênio", capacity: 23000 },
    { name: "Patrocinense", city: "Patrocínio", founded: 1999, stadium: "Estádio Pedro Alves do Nascimento", capacity: 13000 }
  ],
  5 => [ # Estadual
    { name: "União Mogi", city: "Mogi das Cruzes", founded: 1937, stadium: "Estádio Francisco Ribeiro Nogueira", capacity: 15000 },
    { name: "Taubaté", city: "Taubaté", founded: 1914, stadium: "Estádio Joaquim de Morais Filho", capacity: 12000 },
    { name: "Inter de Limeira", city: "Limeira", founded: 1913, stadium: "Estádio Major José Levy Sobrinho", capacity: 20000 },
    { name: "Portuguesa", city: "São Paulo", founded: 1920, stadium: "Estádio do Canindé", capacity: 21004 },
    { name: "XV de Piracicaba", city: "Piracicaba", founded: 1913, stadium: "Estádio Barão de Serra Negra", capacity: 18277 },
    { name: "Rio Claro", city: "Rio Claro", founded: 1909, stadium: "Estádio Augusto Schmidt Filho", capacity: 4500 },
    { name: "Marília", city: "Marília", founded: 1942, stadium: "Estádio Bento de Abreu", capacity: 18000 },
    { name: "Comercial-SP", city: "Ribeirão Preto", founded: 1911, stadium: "Estádio Palma Travassos", capacity: 29292 },
    { name: "Desportivo Brasil", city: "Porto Feliz", founded: 2005, stadium: "Estádio Distrital Inamar", capacity: 5000 },
    { name: "São Bento", city: "Sorocaba", founded: 1913, stadium: "Estádio Walter Ribeiro", capacity: 15000 },
    { name: "Linense", city: "Lins", founded: 1927, stadium: "Estádio Gilberto Siqueira Lopes", capacity: 15000 },
    { name: "Nacional-SP", city: "São Paulo", founded: 1919, stadium: "Estádio Nicolau Alayon", capacity: 10000 },
    { name: "Primavera", city: "Indaiatuba", founded: 2007, stadium: "Estádio Municipal Dr. Mário Beni", capacity: 7500 },
    { name: "Rio Branco-SP", city: "Americana", founded: 1913, stadium: "Estádio Décio Vitta", capacity: 17000 },
    { name: "Francana", city: "Franca", founded: 1912, stadium: "Estádio Lancha Filho", capacity: 12000 },
    { name: "Catanduvense", city: "Catanduva", founded: 1918, stadium: "Estádio Silvio Salles", capacity: 17000 }
  ]
}

# Create template rooms for each division to hold clubs
template_rooms = {}
divisions_data.each do |div_data|
  division = Division.find_by(name: div_data[:name])
  next unless division

  template_room = Room.create!(
    name: "Template #{division.name}",
    user_id: user&.id,
    is_multiplayer: true,
    max_players: 16,
    current_players: 0,
    description: "Template room for #{division.name} clubs",
    status: "waiting"
  )

  template_rooms[division.level] = template_room
  puts "Template room created for #{division.name} (ID: #{template_room.id})"
end

# Create clubs for each division
divisions_data.each do |div_data|
  division = Division.find_by(name: div_data[:name])
  next unless division

  template_room = template_rooms[division.level]
  next unless template_room

  # Skip if clubs already exist for this division
  next if template_room.clubs.count >= 16

  clubs_for_division = all_clubs_data[division.level] || []

  puts "\nCreating 16 clubs for #{division.name} (Template Room ID: #{template_room&.id})..."

  clubs_for_division.each_with_index do |club_data, index|
    # Budget ranges by division level
    budget_ranges = {
      1 => 80_000_000..200_000_000,  # Série A
      2 => 40_000_000..80_000_000,   # Série B
      3 => 20_000_000..40_000_000,   # Série C
      4 => 10_000_000..20_000_000,   # Série D
      5 => 5_000_000..10_000_000     # Estadual
    }

    club = Club.create!(
      name: club_data[:name],
      city: club_data[:city],
      founded_year: club_data[:founded],
      stadium_name: club_data[:stadium],
      stadium_capacity: club_data[:capacity],
      budget: rand(budget_ranges[division.level]),
      division: division,
      room: template_room,  # Assigned to template room
      user_id: nil,  # Available for assignment
      available: true  # Available for room selection
    )

    puts "  #{club.name} (#{club.city}) - Budget: #{club.budget.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}"

    # Create full squad for each club (28 players)
    create_squad_for_club(club)
  end
end

puts "\nSeeds completed successfully!"
puts "Total divisions: #{Division.count}"
puts "Total users: #{User.count}"
puts "Total rooms: #{Room.count}"
puts "Total clubs: #{Club.count}"
puts "Total players: #{Player.count}"
puts "\nDatabase now contains:"
puts "   5 divisions with 16 clubs each (80 total clubs)"
puts "   Each club has 28 players (2,240 total players)"
puts "   Budget ranges by division level"
puts "   All clubs have realistic stadiums and capacities"

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
