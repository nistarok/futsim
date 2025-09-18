class MatchSimulatorService
  attr_reader :match, :home_club, :away_club

  def initialize(match)
    @match = match
    @home_club = match.home_club
    @away_club = match.away_club
  end

  def simulate!
    return false unless match.scheduled?

    match.update!(status: Match::SIMULATING)

    # Calcular força dos times baseada nos atributos detalhados
    home_strength = calculate_team_strength(home_club, is_home: true)
    away_strength = calculate_team_strength(away_club, is_home: false)

    # Simular eventos da partida
    match_events = simulate_match_events(home_strength, away_strength)

    # Contar gols
    home_goals = match_events.count { |event| event[:type] == :goal && event[:team] == :home }
    away_goals = match_events.count { |event| event[:type] == :goal && event[:team] == :away }

    # Finalizar partida
    match.update!(
      home_score: home_goals,
      away_score: away_goals,
      status: Match::COMPLETED,
      match_events: match_events.to_json # Salvar eventos para replay
    )

    true
  end

  private

  def calculate_team_strength(club, is_home: false)
    return { attack: 40, midfield: 40, defense: 40 } if club.players.empty?

    # Calcular força por setor (estilo Elifoot 98)
    attack_strength = calculate_attack_strength(club)
    midfield_strength = calculate_midfield_strength(club)
    defense_strength = calculate_defense_strength(club)

    # Vantagem de casa (+3 pontos em cada setor)
    if is_home
      attack_strength += 3
      midfield_strength += 3
      defense_strength += 3
    end

    # Fator sorte/moral aleatório (-2 a +2)
    luck = rand(-2.0..2.0).round(1)
    attack_strength += luck
    midfield_strength += luck
    defense_strength += luck

    {
      attack: [attack_strength, 30].max,
      midfield: [midfield_strength, 30].max,
      defense: [defense_strength, 30].max
    }
  end

  def calculate_attack_strength(club)
    # Atacantes: LW, RW, ST
    attackers = club.players.where(position: ['LW', 'RW', 'ST']).order(overall: :desc).limit(3)
    return 45 if attackers.empty?

    # Para atacantes: attack e speed são mais importantes
    avg_attack = attackers.average(:attack) || 50
    avg_speed = attackers.average(:speed) || 50
    avg_strength = attackers.average(:strength) || 50
    avg_stamina = attackers.average(:stamina) || 50

    attack_strength = (
      (avg_attack * 0.50) +      # 50% - finalização
      (avg_speed * 0.30) +       # 30% - velocidade para escapar da defesa
      (avg_strength * 0.15) +    # 15% - força para disputas
      (avg_stamina * 0.05)       # 5% - resistência
    ).round(1)

    attack_strength
  end

  def calculate_midfield_strength(club)
    # Meio-campistas: CDM, CM, CAM, LM, RM
    midfielders = club.players.where(position: ['CDM', 'CM', 'CAM', 'LM', 'RM']).order(overall: :desc).limit(4)
    return 45 if midfielders.empty?

    # Para meio-campo: passing e stamina são cruciais
    avg_passing = midfielders.average(:passing) || 50
    avg_stamina = midfielders.average(:stamina) || 50
    avg_attack = midfielders.average(:attack) || 50
    avg_defense = midfielders.average(:defense) || 50

    midfield_strength = (
      (avg_passing * 0.40) +     # 40% - qualidade dos passes
      (avg_stamina * 0.30) +     # 30% - resistência para dominar o jogo
      (avg_defense * 0.15) +     # 15% - marcação no meio
      (avg_attack * 0.15)        # 15% - criação de jogadas
    ).round(1)

    midfield_strength
  end

  def calculate_defense_strength(club)
    # Goleiro + Defensores: GK, CB, LB, RB
    goalkeeper = club.players.where(position: 'GK').order(overall: :desc).first
    defenders = club.players.where(position: ['CB', 'LB', 'RB']).order(overall: :desc).limit(4)

    return 45 if !goalkeeper && defenders.empty?

    # Força do goleiro (peso maior)
    gk_strength = if goalkeeper
      gk_defense = goalkeeper.defense || 50
      gk_strength_attr = goalkeeper.strength || 50
      (gk_defense * 0.70) + (gk_strength_attr * 0.30) # Goleiro = 70% defense, 30% strength
    else
      40 # Goleiro fraco se não tiver
    end

    # Força da linha defensiva
    def_strength = if defenders.any?
      avg_defense = defenders.average(:defense) || 50
      avg_strength = defenders.average(:strength) || 50
      avg_speed = defenders.average(:speed) || 50

      (avg_defense * 0.50) + (avg_strength * 0.30) + (avg_speed * 0.20)
    else
      40 # Defesa fraca se não tiver defensores
    end

    # Combinar goleiro (40%) + linha defensiva (60%)
    defense_strength = (gk_strength * 0.40) + (def_strength * 0.60)
    defense_strength.round(1)
  end

  def simulate_match_events(home_strength, away_strength)
    events = []

    # Calcular domínio de meio-campo (quem cria mais oportunidades)
    home_midfield_dominance = calculate_midfield_dominance(
      home_strength[:midfield],
      away_strength[:midfield]
    )

    # Simular 18 "eventos" ao longo da partida (aproximadamente a cada 5 minutos)
    (1..18).each do |period|
      minute = (period * 5) + rand(-2..2) # Minutos 3-92 aproximadamente
      minute = [[minute, 1].max, 90].min # Entre 1 e 90

      # Determinar qual time está atacando baseado no domínio do meio-campo
      attacking_team = rand < home_midfield_dominance ? :home : :away

      # Confronto setorial: Ataque vs Defesa
      if attacking_team == :home
        attack_power = home_strength[:attack]
        defense_power = away_strength[:defense]
      else
        attack_power = away_strength[:attack]
        defense_power = home_strength[:defense]
      end

      # Chance de criar oportunidade baseada no confronto ataque vs defesa
      opportunity_chance = calculate_opportunity_chance(attack_power, defense_power)

      if rand < opportunity_chance
        # Chance de converter em gol
        goal_chance = calculate_goal_chance(attack_power, defense_power)

        if rand < goal_chance
          events << {
            type: :goal,
            team: attacking_team,
            minute: minute,
            description: generate_goal_description(attacking_team),
            attack_power: attack_power.round(1),
            defense_power: defense_power.round(1)
          }
        else
          # Oportunidade perdida
          events << {
            type: :chance,
            team: attacking_team,
            minute: minute,
            description: generate_chance_description(attacking_team),
            attack_power: attack_power.round(1),
            defense_power: defense_power.round(1)
          }
        end
      end

      # Chance adicional de contra-ataque (baseado em speed dos atacantes)
      if rand < 0.15 # 15% chance de contra-ataque
        counter_attacking_team = attacking_team == :home ? :away : :home

        if counter_attacking_team == :home
          counter_attack_power = home_strength[:attack] * 0.8 # Contra-ataque é menos eficaz
          counter_defense_power = away_strength[:defense] * 1.2 # Defesa despreparada
        else
          counter_attack_power = away_strength[:attack] * 0.8
          counter_defense_power = home_strength[:defense] * 1.2
        end

        counter_opportunity = calculate_opportunity_chance(counter_attack_power, counter_defense_power)

        if rand < counter_opportunity
          counter_goal_chance = calculate_goal_chance(counter_attack_power, counter_defense_power)

          if rand < counter_goal_chance
            events << {
              type: :goal,
              team: counter_attacking_team,
              minute: minute + 1,
              description: "Contra-ataque letal resulta em gol!",
              is_counter: true
            }
          end
        end
      end
    end

    events.sort_by { |event| event[:minute] }
  end

  def calculate_midfield_dominance(home_midfield, away_midfield)
    total_midfield = home_midfield + away_midfield
    home_dominance = home_midfield / total_midfield

    # Adicionar um pouco de aleatoriedade (10%)
    random_factor = rand(-0.05..0.05)
    final_dominance = home_dominance + random_factor

    # Limitar entre 20% e 80%
    [[final_dominance, 0.20].max, 0.80].min
  end

  def calculate_opportunity_chance(attack_strength, defense_strength)
    # Chance base de 30%
    base_chance = 0.30

    # Ajustar baseado na diferença de força
    strength_diff = attack_strength - defense_strength
    modifier = strength_diff * 0.01 # 1% por ponto de diferença

    opportunity_chance = base_chance + modifier

    # Limitar entre 10% e 70%
    [[opportunity_chance, 0.10].max, 0.70].min
  end

  def calculate_goal_chance(attack_strength, defense_strength)
    # Chance base de converter oportunidade em gol: 25%
    base_chance = 0.25

    # Ajustar baseado na diferença de força
    strength_diff = attack_strength - defense_strength
    modifier = strength_diff * 0.008 # 0.8% por ponto de diferença

    goal_chance = base_chance + modifier

    # Limitar entre 5% e 50%
    [[goal_chance, 0.05].max, 0.50].min
  end

  def generate_goal_description(team)
    descriptions = [
      "Gol após bela jogada coletiva!",
      "Finalização certeira na área!",
      "Gol de cabeça após cobrança de escanteio!",
      "Contra-ataque letal resulta em gol!",
      "Chute de fora da área surpreende o goleiro!",
      "Gol após rebote na área!",
      "Pênalti convertido com categoria!",
      "Gol olímpico diretamente do escanteio!"
    ]

    descriptions.sample
  end

  def generate_chance_description(team)
    descriptions = [
      "Grande chance perdida na área!",
      "Chute passou raspando a trave!",
      "Goleiro fez defesa espetacular!",
      "Cabeçada foi para fora por pouco!",
      "Finalização foi bloqueada pela defesa!",
      "Chute saiu fraco nas mãos do goleiro!"
    ]

    descriptions.sample
  end
end