class PlayerPoolGeneratorService
  # Clubes brasileiros com seus elencos fixos
  BRAZILIAN_CLUBS = {
    'Flamengo' => {
      city: 'Rio de Janeiro, RJ',
      stadium: 'Maracanã',
      capacity: 78838,
      players: [
        { name: 'Rossi', position: 'GK', overall: 82 },
        { name: 'Matheus Cunha', position: 'GK', overall: 75 },
        { name: 'Fabrício Bruno', position: 'CB', overall: 84 },
        { name: 'Léo Pereira', position: 'CB', overall: 81 },
        { name: 'David Luiz', position: 'CB', overall: 83 },
        { name: 'Ayrton Lucas', position: 'LB', overall: 80 },
        { name: 'Filipe Luís', position: 'LB', overall: 85 },
        { name: 'Wesley', position: 'RB', overall: 79 },
        { name: 'Varela', position: 'RB', overall: 82 },
        { name: 'Erick Pulgar', position: 'CDM', overall: 84 },
        { name: 'Allan', position: 'CDM', overall: 81 },
        { name: 'Gerson', position: 'CM', overall: 86 },
        { name: 'Arrascaeta', position: 'CAM', overall: 88 },
        { name: 'Bruno Henrique', position: 'LW', overall: 85 },
        { name: 'Everton Cebolinha', position: 'RW', overall: 83 },
        { name: 'Pedro', position: 'ST', overall: 89 },
        { name: 'Gabigol', position: 'ST', overall: 87 }
      ]
    },
    'Palmeiras' => {
      city: 'São Paulo, SP',
      stadium: 'Allianz Parque',
      capacity: 43713,
      players: [
        { name: 'Weverton', position: 'GK', overall: 85 },
        { name: 'Marcelo Lomba', position: 'GK', overall: 78 },
        { name: 'Gustavo Gómez', position: 'CB', overall: 86 },
        { name: 'Murilo', position: 'CB', overall: 82 },
        { name: 'Luan', position: 'CB', overall: 79 },
        { name: 'Piquerez', position: 'LB', overall: 83 },
        { name: 'Vanderlan', position: 'LB', overall: 76 },
        { name: 'Marcos Rocha', position: 'RB', overall: 81 },
        { name: 'Mayke', position: 'RB', overall: 78 },
        { name: 'Richard Ríos', position: 'CDM', overall: 84 },
        { name: 'Zé Rafael', position: 'CM', overall: 83 },
        { name: 'Raphael Veiga', position: 'CAM', overall: 87 },
        { name: 'Estêvão', position: 'RW', overall: 85 },
        { name: 'Dudu', position: 'LW', overall: 84 },
        { name: 'Rony', position: 'ST', overall: 82 },
        { name: 'Flaco López', position: 'ST', overall: 80 }
      ]
    },
    'Santos' => {
      city: 'Santos, SP',
      stadium: 'Vila Belmiro',
      capacity: 16068,
      players: [
        { name: 'João Paulo', position: 'GK', overall: 79 },
        { name: 'Brazão', position: 'GK', overall: 72 },
        { name: 'Gil', position: 'CB', overall: 80 },
        { name: 'Joaquim', position: 'CB', overall: 77 },
        { name: 'Jair', position: 'CB', overall: 75 },
        { name: 'Escobar', position: 'LB', overall: 78 },
        { name: 'Hayner', position: 'RB', overall: 76 },
        { name: 'João Schmidt', position: 'CDM', overall: 79 },
        { name: 'Diego Pituca', position: 'CM', overall: 81 },
        { name: 'Giuliano', position: 'CAM', overall: 84 },
        { name: 'Otero', position: 'LW', overall: 80 },
        { name: 'William', position: 'RW', overall: 78 },
        { name: 'Marcos Leonardo', position: 'ST', overall: 83 },
        { name: 'Soteldo', position: 'ST', overall: 82 }
      ]
    },
    'São Paulo' => {
      city: 'São Paulo, SP',
      stadium: 'Morumbi',
      capacity: 67052,
      players: [
        { name: 'Rafael', position: 'GK', overall: 83 },
        { name: 'Jandrei', position: 'GK', overall: 80 },
        { name: 'Arboleda', position: 'CB', overall: 84 },
        { name: 'Diego Costa', position: 'CB', overall: 81 },
        { name: 'Alan Franco', position: 'CB', overall: 82 },
        { name: 'Welington', position: 'LB', overall: 80 },
        { name: 'Rafinha', position: 'RB', overall: 83 },
        { name: 'Pablo Maia', position: 'CDM', overall: 79 },
        { name: 'Alisson', position: 'CM', overall: 78 },
        { name: 'Lucas', position: 'CAM', overall: 85 },
        { name: 'Michel Araújo', position: 'LW', overall: 77 },
        { name: 'Ferreira', position: 'RW', overall: 81 },
        { name: 'Calleri', position: 'ST', overall: 86 },
        { name: 'André Silva', position: 'ST', overall: 84 }
      ]
    }
  }

  def initialize(room)
    @room = room
  end

  def generate_default_clubs!
    return if @room.clubs.any? # Não gerar se já existem clubes

    ActiveRecord::Base.transaction do
      # Pegar 16 clubes das salas template (identificadas pela descrição)
      template_rooms = Room.where("description LIKE ?", "Template room for%")
      available_clubs = Club.where(room: template_rooms, available: true)
                           .includes(:division, :players)
                           .limit(16)

      if available_clubs.count < 16
        Rails.logger.error "Not enough available clubs in database. Found #{available_clubs.count}, need 16."
        return
      end

      available_clubs.each do |source_club|
        # Criar cópia do clube para esta sala
        room_club = @room.clubs.create!(
          name: source_club.name,
          city: source_club.city,
          stadium_name: source_club.stadium_name,
          stadium_capacity: source_club.stadium_capacity,
          founded_year: source_club.founded_year,
          budget: source_club.budget,
          division: source_club.division,
          user: nil, # Nenhum usuário inicialmente
          available: true # Disponível para escolha
        )

        # Copiar jogadores do clube original
        source_club.players.each do |source_player|
          room_club.players.create!(
            name: source_player.name,
            age: source_player.age,
            position: source_player.position,
            overall: source_player.overall,
            strength: source_player.strength,
            stamina: source_player.stamina,
            speed: source_player.speed,
            attack: source_player.attack,
            defense: source_player.defense,
            passing: source_player.passing,
            salary: source_player.salary,
            market_value: source_player.market_value,
            nationality: source_player.nationality || 'BRA'
          )
        end

        Rails.logger.info "Copied club #{room_club.name} (#{room_club.division.name}) to room #{@room.name}"
      end
    end

    Rails.logger.info "Generated #{@room.clubs.count} clubs for room #{@room.name} from database pool"
  end

  private

  def create_player_for_club(club, player_data)
    age = rand(18..33)
    overall = player_data[:overall]

    # Gerar atributos baseados no overall e posição
    attributes = generate_attributes_for_position(player_data[:position], overall)

    salary = calculate_salary(overall, age)
    market_value = calculate_market_value(overall, age)

    Player.create!(
      club: club,
      name: player_data[:name],
      age: age,
      position: player_data[:position],
      overall: overall,
      strength: attributes[:strength],
      stamina: attributes[:stamina],
      speed: attributes[:speed],
      attack: attributes[:attack],
      defense: attributes[:defense],
      passing: attributes[:passing],
      salary: salary,
      market_value: market_value
    )
  end

  def generate_attributes_for_position(position, overall)
    base_variation = 5 # Variação base dos atributos

    case position
    when 'GK'
      {
        strength: rand((overall - base_variation)..(overall + base_variation)),
        stamina: rand((overall - 10)..(overall)),
        speed: rand((overall - 15)..(overall - 5)),
        attack: rand(30..50),
        defense: rand((overall - base_variation)..(overall + base_variation)),
        passing: rand((overall - 10)..(overall))
      }
    when 'CB'
      {
        strength: rand((overall - base_variation)..(overall + base_variation)),
        stamina: rand((overall - 5)..(overall + 5)),
        speed: rand((overall - 10)..(overall)),
        attack: rand(40..65),
        defense: rand((overall - base_variation)..(overall + base_variation)),
        passing: rand((overall - 10)..(overall))
      }
    when 'LB', 'RB'
      {
        strength: rand((overall - 8)..(overall)),
        stamina: rand((overall - base_variation)..(overall + base_variation)),
        speed: rand((overall - base_variation)..(overall + base_variation)),
        attack: rand((overall - 15)..(overall)),
        defense: rand((overall - 8)..(overall + 5)),
        passing: rand((overall - 5)..(overall + 5))
      }
    when 'CDM'
      {
        strength: rand((overall - 5)..(overall + 5)),
        stamina: rand((overall - base_variation)..(overall + base_variation)),
        speed: rand((overall - 10)..(overall)),
        attack: rand((overall - 15)..(overall - 5)),
        defense: rand((overall - 5)..(overall + 5)),
        passing: rand((overall - base_variation)..(overall + base_variation))
      }
    when 'CM'
      {
        strength: rand((overall - 8)..(overall)),
        stamina: rand((overall - base_variation)..(overall + base_variation)),
        speed: rand((overall - 8)..(overall + 5)),
        attack: rand((overall - 10)..(overall + 5)),
        defense: rand((overall - 10)..(overall)),
        passing: rand((overall - base_variation)..(overall + base_variation))
      }
    when 'CAM'
      {
        strength: rand((overall - 10)..(overall)),
        stamina: rand((overall - 8)..(overall + 5)),
        speed: rand((overall - 5)..(overall + 5)),
        attack: rand((overall - base_variation)..(overall + base_variation)),
        defense: rand((overall - 15)..(overall - 5)),
        passing: rand((overall - base_variation)..(overall + base_variation))
      }
    when 'LM', 'RM'
      {
        strength: rand((overall - 10)..(overall)),
        stamina: rand((overall - base_variation)..(overall + base_variation)),
        speed: rand((overall - base_variation)..(overall + base_variation)),
        attack: rand((overall - 8)..(overall + 5)),
        defense: rand((overall - 12)..(overall)),
        passing: rand((overall - 5)..(overall + 5))
      }
    when 'LW', 'RW'
      {
        strength: rand((overall - 12)..(overall)),
        stamina: rand((overall - 8)..(overall + 5)),
        speed: rand((overall - base_variation)..(overall + base_variation)),
        attack: rand((overall - base_variation)..(overall + base_variation)),
        defense: rand((overall - 20)..(overall - 5)),
        passing: rand((overall - 8)..(overall + 5))
      }
    when 'ST'
      {
        strength: rand((overall - 5)..(overall + 5)),
        stamina: rand((overall - 10)..(overall)),
        speed: rand((overall - 8)..(overall + 5)),
        attack: rand((overall - base_variation)..(overall + base_variation)),
        defense: rand((overall - 20)..(overall - 10)),
        passing: rand((overall - 10)..(overall))
      }
    end
  end


  def calculate_salary(overall, age)
    base_salary = overall * 1000

    # Jogadores mais velhos ganham mais (experiência)
    age_multiplier = case age
    when 16..20 then 0.5
    when 21..25 then 0.8
    when 26..30 then 1.2
    when 31..35 then 1.0
    else 0.8
    end

    (base_salary * age_multiplier).round
  end

  def calculate_market_value(overall, age)
    base_value = overall * 10000

    # Jogadores mais jovens valem mais
    age_multiplier = case age
    when 16..20 then 1.5
    when 21..25 then 1.3
    when 26..28 then 1.0
    when 29..31 then 0.8
    when 32..35 then 0.5
    else 0.3
    end

    (base_value * age_multiplier).round
  end
end