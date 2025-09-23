# Encontrar a sala de teste
room = Room.find(7)
puts "Sala encontrada: #{room.name}"

# Verificar se já existe uma rodada
existing_round = room.rounds.first
if existing_round
  puts "Rodada existente encontrada: #{existing_round.id}"
  round = existing_round
else
  # Criar uma nova rodada
  round = room.rounds.create!(
    number: 1,
    status: "preparation",
    start_date: Date.current,
    end_date: Date.current + 7.days
  )
  puts "Nova rodada criada: #{round.id}"

  # Gerar confrontos para clubes ocupados
  clubs = room.clubs.joins(:user).includes(:user)
  puts "Clubes ocupados: #{clubs.count}"

  if clubs.count >= 2
    clubs = clubs.to_a.shuffle
    (clubs.count / 2).times do |i|
      home_club = clubs[i * 2]
      away_club = clubs[i * 2 + 1]

      match = round.matches.create!(
        home_club: home_club,
        away_club: away_club,
        match_date: round.start_date,
        status: "scheduled"
      )
      puts "Confronto criado: #{home_club.name} vs #{away_club.name}"
    end
  end
end

puts "Rodada ID: #{round.id} - Status: #{round.status}"
puts "Matches: #{round.matches.count}"

# Listar matches
round.matches.each do |match|
  puts "  #{match.home_club.name} vs #{match.away_club.name} - Status: #{match.status}"
end

# Se houver matches, vamos simular
if round.matches.any?
  puts "\n=== INICIANDO SIMULAÇÃO ==="

  # Marcar rodada como aprovada para simular
  round.update!(status: "approved")
  puts "Rodada marcada como aprovada"

  # Simular cada partida
  round.matches.scheduled.each do |match|
    puts "\nSimulando: #{match.home_club.name} vs #{match.away_club.name}"

    simulator = MatchSimulatorService.new(match)
    success = simulator.simulate!

    if success
      match.reload
      puts "Resultado: #{match.home_club.name} #{match.home_score} x #{match.away_score} #{match.away_club.name}"

      # Mostrar alguns eventos se existirem
      if match.match_events.present?
        events = JSON.parse(match.match_events)
        puts "Eventos da partida:"
        events.first(3).each do |event|
          puts "  #{event['minute']}' - #{event['description']}"
        end
      end
    else
      puts "Erro ao simular a partida"
    end
  end

  # Marcar rodada como concluída
  round.update!(status: "completed")
  puts "\n=== SIMULAÇÃO CONCLUÍDA ==="
  puts "Rodada ID: #{round.id} finalizada com sucesso!"
end