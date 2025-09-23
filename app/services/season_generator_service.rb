class SeasonGeneratorService
  attr_reader :room, :season_year

  def initialize(room, season_year = Date.current.year)
    @room = room
    @season_year = season_year
  end

  def generate_complete_season!
    Rails.logger.info "Gerando temporada completa para room #{room.id} (#{season_year})"

    clubs = room.clubs.includes(:user).to_a
    raise "Precisa de pelo menos 2 clubes para gerar temporada" if clubs.size < 2

    # Calcular total de rodadas (round-robin duplo - ida e volta)
    total_rounds = calculate_total_rounds(clubs.size)

    Rails.logger.info "Gerando #{total_rounds} rodadas para #{clubs.size} clubes"

    # Gerar todas as rodadas da temporada
    generate_all_rounds(clubs, total_rounds)

    # Marcar primeira rodada como ativa
    first_round = room.rounds.order(:number).first
    first_round&.update!(status: Round::PREPARATION)

    Rails.logger.info "Temporada completa gerada com sucesso!"

    {
      total_rounds: total_rounds,
      total_matches: room.matches.count,
      clubs_count: clubs.size
    }
  end

  private

  def calculate_total_rounds(clubs_count)
    # Round-robin duplo: cada time joga contra todos os outros 2 vezes (ida e volta)
    # Formula: 2 * (n - 1) onde n é o número de times
    2 * (clubs_count - 1)
  end

  def generate_all_rounds(clubs, total_rounds)
    # Limpar rodadas existentes
    room.rounds.destroy_all

    # Gerar combinações de confrontos para round-robin duplo
    matches_schedule = generate_round_robin_schedule(clubs)

    # Criar rodadas e partidas
    matches_schedule.each_with_index do |(round_matches, is_return_leg), round_index|
      round_number = round_index + 1

      # Calcular datas da rodada
      round_start_date = Date.current + (round_index * 7).days
      round_end_date = round_start_date + 6.days

      # Criar rodada
      round = room.rounds.create!(
        number: round_number,
        status: Round::PREPARATION,
        start_date: round_start_date,
        end_date: round_end_date
      )

      Rails.logger.info "Criando rodada #{round_number}#{is_return_leg ? ' (returno)' : ' (turno)'}"

      # Criar partidas da rodada
      round_matches.each do |match_info|
        home_club = match_info[:home]
        away_club = match_info[:away]

        round.matches.create!(
          home_club: home_club,
          away_club: away_club,
          match_date: round_start_date + rand(0..6).days,
          status: Match::SCHEDULED
        )

        Rails.logger.debug "  #{home_club.name} x #{away_club.name}"
      end
    end
  end

  def generate_round_robin_schedule(clubs)
    clubs_count = clubs.size

    # Se número ímpar de times, adicionar "bye" (folga)
    if clubs_count.odd?
      clubs = clubs + [nil] # nil representa folga
      clubs_count += 1
    end

    # Gerar rodadas de ida (turno)
    first_leg_rounds = []

    # Algoritmo round-robin clássico
    (clubs_count - 1).times do |round|
      round_matches = []

      (clubs_count / 2).times do |match|
        home_index = match
        away_index = clubs_count - 1 - match

        # Ajustar índices para rotação
        unless round == 0
          home_index = (home_index + round) % (clubs_count - 1)
          away_index = (away_index + round) % (clubs_count - 1)
        end

        # Time fixo sempre fica na última posição
        if match == 0
          away_index = clubs_count - 1
        end

        home_club = clubs[home_index]
        away_club = clubs[away_index]

        # Pular se algum time for nil (folga)
        next if home_club.nil? || away_club.nil?

        round_matches << { home: home_club, away: away_club }
      end

      first_leg_rounds << [round_matches, false] # false = turno
    end

    # Gerar rodadas de volta (returno) - invertendo os mandos de campo
    second_leg_rounds = first_leg_rounds.map do |round_matches, _|
      inverted_matches = round_matches.first.map do |match_info|
        { home: match_info[:away], away: match_info[:home] }
      end
      [inverted_matches, true] # true = returno
    end

    # Retornar turno + returno
    first_leg_rounds + second_leg_rounds
  end
end