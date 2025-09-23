# Lineup Test Helper
# Helpers compartilhados para testes do sistema de escalação

module LineupTestHelper
  # Criar clube com elenco completo para testes
  def create_test_club_with_full_squad
    club = clubs(:fluminense) || Club.create!(
      name: "Test Club",
      city: "Test City",
      founded: 1950
    )

    # Criar jogadores para todas as posições
    positions = {
      'GK' => 3, 'CB' => 4, 'LB' => 2, 'RB' => 2,
      'CDM' => 2, 'CM' => 4, 'CAM' => 2,
      'LM' => 1, 'RM' => 1, 'LW' => 2, 'RW' => 2, 'ST' => 3
    }

    positions.each do |position, count|
      count.times do |i|
        create_player(club: club, position: position, overall: 75 + rand(15))
      end
    end

    club
  end

  # Criar jogador com atributos realistas baseados na posição
  def create_player(club:, position:, overall: 75, name: nil)
    player_name = name || generate_player_name(position)

    # Atributos base
    base_attributes = {
      club: club,
      name: player_name,
      position: position,
      overall: overall,
      age: 18 + rand(17), # 18-34 anos
      nationality: 'BR'
    }

    # Atributos específicos por posição
    position_attributes = generate_position_specific_attributes(position, overall)

    Player.create!(base_attributes.merge(position_attributes))
  end

  # Gerar nome realista para jogador
  def generate_player_name(position)
    first_names = [
      'João', 'Pedro', 'Lucas', 'Gabriel', 'Rafael', 'Mateus', 'Felipe', 'Diego',
      'Bruno', 'André', 'Carlos', 'Fernando', 'Ricardo', 'Roberto', 'Marcelo'
    ]

    last_names = [
      'Silva', 'Santos', 'Oliveira', 'Souza', 'Rodrigues', 'Ferreira', 'Costa',
      'Pereira', 'Carvalho', 'Almeida', 'Lima', 'Gomes', 'Martins', 'Rocha'
    ]

    "#{first_names.sample} #{last_names.sample}"
  end

  # Gerar atributos específicos baseados na posição
  def generate_position_specific_attributes(position, overall)
    base_variation = 15
    min_val = [overall - base_variation, 50].max
    max_val = [overall + base_variation, 99].min

    case position
    when 'GK'
      {
        goalkeeping: rand_attribute(overall + 5, 5),
        reflexes: rand_attribute(overall + 3, 5),
        handling: rand_attribute(overall, 8),
        kicking: rand_attribute(overall - 5, 10),
        positioning: rand_attribute(overall + 2, 6),
        jumping: rand_attribute(overall - 2, 8)
      }
    when 'CB'
      {
        defense: rand_attribute(overall + 5, 5),
        strength: rand_attribute(overall + 3, 7),
        heading: rand_attribute(overall + 2, 6),
        tackling: rand_attribute(overall + 4, 6),
        positioning: rand_attribute(overall + 1, 8),
        pace: rand_attribute(overall - 10, 12)
      }
    when 'LB', 'RB'
      {
        defense: rand_attribute(overall + 2, 8),
        pace: rand_attribute(overall + 3, 7),
        crossing: rand_attribute(overall, 10),
        stamina: rand_attribute(overall + 4, 6),
        tackling: rand_attribute(overall + 1, 8),
        dribbling: rand_attribute(overall - 3, 10)
      }
    when 'CDM'
      {
        defense: rand_attribute(overall + 3, 6),
        passing: rand_attribute(overall + 2, 7),
        tackling: rand_attribute(overall + 4, 5),
        stamina: rand_attribute(overall + 3, 6),
        positioning: rand_attribute(overall + 1, 8),
        strength: rand_attribute(overall, 8)
      }
    when 'CM'
      {
        passing: rand_attribute(overall + 4, 6),
        stamina: rand_attribute(overall + 5, 5),
        dribbling: rand_attribute(overall + 1, 8),
        attack: rand_attribute(overall - 2, 10),
        defense: rand_attribute(overall - 2, 10),
        positioning: rand_attribute(overall + 2, 7)
      }
    when 'CAM'
      {
        passing: rand_attribute(overall + 5, 5),
        attack: rand_attribute(overall + 3, 7),
        dribbling: rand_attribute(overall + 4, 6),
        creativity: rand_attribute(overall + 6, 4),
        finishing: rand_attribute(overall + 1, 8),
        pace: rand_attribute(overall, 8)
      }
    when 'LM', 'RM'
      {
        pace: rand_attribute(overall + 4, 6),
        crossing: rand_attribute(overall + 5, 5),
        dribbling: rand_attribute(overall + 3, 7),
        stamina: rand_attribute(overall + 4, 6),
        passing: rand_attribute(overall, 8),
        defense: rand_attribute(overall - 5, 12)
      }
    when 'LW', 'RW'
      {
        pace: rand_attribute(overall + 5, 5),
        dribbling: rand_attribute(overall + 4, 6),
        attack: rand_attribute(overall + 3, 7),
        crossing: rand_attribute(overall + 2, 8),
        finishing: rand_attribute(overall + 1, 8),
        strength: rand_attribute(overall - 5, 12)
      }
    when 'ST'
      {
        attack: rand_attribute(overall + 6, 4),
        finishing: rand_attribute(overall + 5, 5),
        strength: rand_attribute(overall + 2, 8),
        pace: rand_attribute(overall + 3, 7),
        heading: rand_attribute(overall + 1, 8),
        positioning: rand_attribute(overall + 4, 6)
      }
    else
      # Atributos genéricos se posição não reconhecida
      {
        passing: rand_attribute(overall, 8),
        attack: rand_attribute(overall, 8),
        defense: rand_attribute(overall, 8),
        pace: rand_attribute(overall, 8),
        stamina: rand_attribute(overall, 8),
        strength: rand_attribute(overall, 8)
      }
    end
  end

  # Gerar atributo aleatório com variação controlada
  def rand_attribute(base, variation)
    min_val = [base - variation, 30].max
    max_val = [base + variation, 99].min
    rand(min_val..max_val)
  end

  # Limpar elenco existente
  def clear_squad(club)
    club.players.destroy_all
  end

  # Criar elenco desbalanceado para testes
  def create_unbalanced_squad(club, position_distribution)
    clear_squad(club)

    position_distribution.each do |position, count|
      count.times do |i|
        create_player(
          club: club,
          position: position,
          overall: 70 + rand(20),
          name: "#{position} Player #{i + 1}"
        )
      end
    end
  end

  # Criar elenco específico para teste de química
  def create_chemistry_test_squad(club)
    clear_squad(club)

    # Goleiro com stats ideais
    create_player(club: club, position: 'GK', overall: 75, name: 'Perfect GK')
    club.players.last.update!(goalkeeping: 90, reflexes: 85)

    # Zagueiro com stats ideais
    create_player(club: club, position: 'CB', overall: 75, name: 'Perfect CB')
    club.players.last.update!(defense: 90, strength: 85, heading: 80)

    # Meio-campo versátil
    create_player(club: club, position: 'CM', overall: 75, name: 'Versatile CM')
    club.players.last.update!(passing: 85, stamina: 88, attack: 70, defense: 75)

    # Atacante com stats ideais
    create_player(club: club, position: 'ST', overall: 75, name: 'Perfect ST')
    club.players.last.update!(attack: 90, finishing: 88, pace: 85)

    # Completar elenco com jogadores médios
    remaining_positions = {
      'CB' => 2, 'LB' => 2, 'RB' => 2, 'CDM' => 2,
      'CM' => 2, 'CAM' => 1, 'LW' => 1, 'RW' => 1, 'ST' => 1
    }

    remaining_positions.each do |position, count|
      count.times do |i|
        create_player(club: club, position: position, overall: 70 + rand(10))
      end
    end
  end

  # Verificar se clube tem elenco mínimo
  def ensure_minimum_squad(club, min_players = 22)
    current_count = club.players.count

    if current_count < min_players
      needed = min_players - current_count
      positions = %w[GK CB LB RB CDM CM CAM LM RM LW RW ST]

      needed.times do |i|
        position = positions[i % positions.length]
        create_player(club: club, position: position, overall: 65 + rand(20))
      end
    end
  end

  # Assertions customizadas para testes de escalação
  def assert_valid_lineup(selected_players)
    assert_equal 11, selected_players.count, "Escalação deve ter exatamente 11 jogadores"
    assert selected_players.any? { |p| p.position == 'GK' }, "Deve ter pelo menos 1 goleiro"

    # Verificar posições mínimas
    defenders = selected_players.select { |p| %w[CB LB RB].include?(p.position) }
    midfielders = selected_players.select { |p| %w[CDM CM CAM LM RM].include?(p.position) }
    attackers = selected_players.select { |p| %w[LW RW ST].include?(p.position) }

    assert defenders.count >= 3, "Deve ter pelo menos 3 defensores"
    assert midfielders.count >= 2, "Deve ter pelo menos 2 meio-campistas"
    assert attackers.count >= 1, "Deve ter pelo menos 1 atacante"
  end

  def assert_formation_viable(formation, squad)
    formation_limits = get_formation_limits(formation)
    formation_limits.each do |position, needed|
      available = squad.select { |p| p.position == position }.count
      compatible = count_compatible_players(squad, position)

      assert (available + compatible) >= needed,
        "Formação #{formation} não é viável: precisa #{needed} #{position}, tem #{available} + #{compatible} compatíveis"
    end
  end

  private

  def get_formation_limits(formation)
    case formation
    when '4-4-2'
      { 'GK' => 1, 'CB' => 2, 'LB' => 1, 'RB' => 1, 'CDM' => 2, 'CM' => 2, 'ST' => 2 }
    when '4-3-3'
      { 'GK' => 1, 'CB' => 2, 'LB' => 1, 'RB' => 1, 'CDM' => 1, 'CM' => 2, 'ST' => 1, 'LW' => 1, 'RW' => 1 }
    when '5-3-2'
      { 'GK' => 1, 'CB' => 3, 'LB' => 1, 'RB' => 1, 'CM' => 3, 'ST' => 2 }
    else
      {}
    end
  end

  def count_compatible_players(squad, target_position)
    compatibility_matrix = {
      'CB' => %w[CDM LB RB],
      'CDM' => %w[CB CM],
      'CM' => %w[CDM CAM LM RM],
      'ST' => %w[CAM LW RW]
    }

    compatible_positions = compatibility_matrix[target_position] || []
    squad.count { |p| compatible_positions.include?(p.position) }
  end
end