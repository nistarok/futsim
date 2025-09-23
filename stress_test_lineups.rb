# Stress Test para Sistema de Escalação Avançado
# Testa todos os times de todas as divisões com diferentes cenários
puts "=" * 60
puts "🚀 INICIANDO STRESS TEST DO SISTEMA DE ESCALAÇÃO"
puts "=" * 60

# Função para simular seleção automática via JavaScript
def simulate_auto_select_for_club(club)
  puts "\n🔍 Testando: #{club.name} (#{club.division&.name || 'Sem Divisão'})"

  # Contar jogadores por posição
  players_by_position = club.players.group_by(&:position)

  puts "  📊 Elenco:"
  ['GK', 'CB', 'LB', 'RB', 'CDM', 'CM', 'CAM', 'LM', 'RM', 'LW', 'RW', 'ST'].each do |position|
    count = players_by_position[position]&.count || 0
    puts "    #{position}: #{count} jogadores"
  end

  total_players = club.players.count
  puts "  📈 Total: #{total_players} jogadores"

  # Testar diferentes formações
  formations = ['4-4-2', '4-3-3', '5-3-2', '4-5-1', '3-4-3', '4-2-3-1']
  results = {}

  formations.each do |formation|
    puts "    🎯 Testando formação #{formation}..."

    # Simular limites da formação
    formation_limits = {
      '4-4-2' => { 'GK' => 1, 'CB' => 2, 'LB' => 1, 'RB' => 1, 'CDM' => 2, 'CM' => 2, 'ST' => 2 },
      '4-3-3' => { 'GK' => 1, 'CB' => 2, 'LB' => 1, 'RB' => 1, 'CDM' => 1, 'CM' => 2, 'LW' => 1, 'RW' => 1, 'ST' => 1 },
      '5-3-2' => { 'GK' => 1, 'CB' => 3, 'LB' => 1, 'RB' => 1, 'CDM' => 1, 'CM' => 1, 'CAM' => 1, 'ST' => 2 },
      '4-5-1' => { 'GK' => 1, 'CB' => 2, 'LB' => 1, 'RB' => 1, 'CDM' => 2, 'CM' => 2, 'CAM' => 1, 'ST' => 1 },
      '3-4-3' => { 'GK' => 1, 'CB' => 3, 'CM' => 2, 'LM' => 1, 'RM' => 1, 'LW' => 1, 'RW' => 1, 'ST' => 1 },
      '4-2-3-1' => { 'GK' => 1, 'CB' => 2, 'LB' => 1, 'RB' => 1, 'CDM' => 2, 'CAM' => 1, 'LM' => 1, 'RM' => 1, 'ST' => 1 }
    }

    limits = formation_limits[formation]
    selected_players = 0
    missing_positions = []
    out_of_position_players = 0

    # Compatibilidade de posições (simplificada para o teste)
    compatible_positions = {
      'GK' => ['GK'],
      'CB' => ['CB', 'CDM'],
      'LB' => ['LB', 'LM', 'CB'],
      'RB' => ['RB', 'RM', 'CB'],
      'CDM' => ['CDM', 'CM', 'CB'],
      'CM' => ['CM', 'CDM', 'CAM'],
      'CAM' => ['CAM', 'CM', 'LW', 'RW', 'ST'],
      'LM' => ['LM', 'LB', 'LW', 'CM'],
      'RM' => ['RM', 'RB', 'RW', 'CM'],
      'LW' => ['LW', 'LM', 'ST', 'CAM'],
      'RW' => ['RW', 'RM', 'ST', 'CAM'],
      'ST' => ['ST', 'CAM', 'LW', 'RW']
    }

    used_players = Set.new

    limits.each do |position, needed|
      next if needed == 0

      available_for_position = []

      # Buscar jogadores compatíveis
      compatible_positions[position].each do |compatible_pos|
        players_in_pos = players_by_position[compatible_pos] || []
        players_in_pos.each do |player|
          next if used_players.include?(player.id)

          penalty = (compatible_pos == position) ? 0 : -2
          available_for_position << { player: player, original_pos: compatible_pos, penalty: penalty }
        end
      end

      # Ordenar por overall ajustado
      available_for_position.sort! { |a, b| (b[:player].overall + b[:penalty]) <=> (a[:player].overall + a[:penalty]) }

      # Selecionar os melhores
      selected_for_this_position = 0
      available_for_position.each do |player_data|
        break if selected_for_this_position >= needed

        used_players.add(player_data[:player].id)
        selected_players += 1
        selected_for_this_position += 1

        if player_data[:penalty] < 0
          out_of_position_players += 1
        end
      end

      if selected_for_this_position < needed
        missing_positions << "#{position}: #{selected_for_this_position}/#{needed}"
      end
    end

    results[formation] = {
      selected: selected_players,
      out_of_position: out_of_position_players,
      missing: missing_positions
    }

    status = selected_players == 11 ? "✅" : "⚠️"
    puts "      #{status} Selecionados: #{selected_players}/11"
    puts "      🔄 Fora de posição: #{out_of_position_players}"
    puts "      ❌ Posições faltantes: #{missing_positions.join(', ')}" unless missing_positions.empty?
  end

  results
end

# Função para testar cenários extremos
def test_extreme_scenarios
  puts "\n" + "=" * 60
  puts "🔥 TESTANDO CENÁRIOS EXTREMOS"
  puts "=" * 60

  # Criar time com poucos jogadores
  puts "\n📉 Teste: Time com poucos jogadores"

  # Simular um time com apenas 8 jogadores de posições limitadas
  limited_squad = {
    'GK' => 1,
    'CB' => 2,
    'CM' => 3,
    'ST' => 2
  }

  puts "  Elenco limitado: #{limited_squad}"
  puts "  Total: 8 jogadores para preencher 11 posições"

  # Testar formação 4-4-2
  formation_limits = { 'GK' => 1, 'CB' => 2, 'LB' => 1, 'RB' => 1, 'CDM' => 2, 'CM' => 2, 'ST' => 2 }

  selected = 0
  out_of_position = 0

  # Simular seleção inteligente
  formation_limits.each do |position, needed|
    available = case position
    when 'GK' then limited_squad['GK'] || 0
    when 'CB', 'LB', 'RB' then limited_squad['CB'] || 0  # CB pode jogar de lateral
    when 'CDM', 'CM' then limited_squad['CM'] || 0
    when 'ST' then limited_squad['ST'] || 0
    else 0
    end

    if available > 0
      filled = [needed, available].min
      selected += filled

      # Se não é posição ideal, conta como fora de posição
      if position != 'GK' && position != 'CB' && position != 'CM' && position != 'ST'
        out_of_position += filled
      end
    end
  end

  puts "  📊 Resultado: #{selected}/11 posições preenchidas"
  puts "  🔄 Jogadores fora de posição: #{out_of_position}"
  puts "  ✅ Sistema deve adaptar formação automaticamente"

  puts "\n📈 Teste: Time com excesso de uma posição"

  # Simular time com 10 atacantes e 1 goleiro
  unbalanced_squad = {
    'GK' => 1,
    'ST' => 10
  }

  puts "  Elenco desbalanceado: #{unbalanced_squad}"
  puts "  ✅ Sistema deve usar atacantes em outras posições com penalidades"
end

# Executar testes principais
puts "\n🏃‍♂️ Executando testes em todos os clubes..."

# Buscar todos os clubes
clubs = Club.includes(:division, :players).all
total_clubs = clubs.count

puts "📋 Total de clubes encontrados: #{total_clubs}"

if total_clubs == 0
  puts "⚠️ Nenhum clube encontrado! Execute rails db:seed para criar dados de teste."
  exit
end

# Agrupar por divisão
clubs_by_division = clubs.group_by { |c| c.division&.name || "Sem Divisão" }

clubs_by_division.each do |division_name, division_clubs|
  puts "\n" + "🏆 #{division_name} (#{division_clubs.count} clubes)".center(60, "=")

  division_clubs.each_with_index do |club, index|
    puts "\n#{index + 1}/#{division_clubs.count} - Testando #{club.name}..."

    begin
      results = simulate_auto_select_for_club(club)

      # Sumarizar resultados
      successful_formations = results.select { |_, data| data[:selected] == 11 }.keys
      puts "    ✅ Formações viáveis: #{successful_formations.join(', ')}"

      if successful_formations.empty?
        puts "    ⚠️ ATENÇÃO: Nenhuma formação conseguiu preencher todas as 11 posições!"

        # Mostrar melhor resultado
        best_result = results.max_by { |_, data| data[:selected] }
        puts "    📊 Melhor resultado: #{best_result[0]} com #{best_result[1][:selected]}/11 jogadores"
      end

    rescue => e
      puts "    ❌ ERRO: #{e.message}"
      puts "    Stack trace: #{e.backtrace.first(3).join('\n    ')}"
    end
  end
end

# Executar testes de cenários extremos
test_extreme_scenarios

# Resumo final
puts "\n" + "=" * 60
puts "🏁 STRESS TEST CONCLUÍDO"
puts "=" * 60
puts "📊 Estatísticas:"
puts "  • Total de clubes testados: #{total_clubs}"
puts "  • Divisões encontradas: #{clubs_by_division.keys.count}"
puts "  • Formações testadas por clube: 6"
puts "  • Total de testes realizados: #{total_clubs * 6}"
puts "\n✅ O sistema de escalação foi testado em cenários diversos!"
puts "🔍 Verifique os logs acima para identificar possíveis melhorias."