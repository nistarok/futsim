#!/usr/bin/env ruby
require_relative 'config/environment'

puts "🏆 TESTE DO SISTEMA DE FORMAÇÕES TÁTICAS"
puts "=" * 50

# Encontrar um clube com escalação
club = Club.joins(:lineups).where(lineups: { active: true }).first

if club.nil?
  puts "❌ Nenhum clube com escalação ativa encontrado!"
  exit 1
end

lineup = club.lineups.active.first
puts "✅ Testando clube: #{club.name}"
puts "📋 Formação atual: #{lineup.formation}"
puts "👥 Jogadores escalados: #{lineup.starting_players.count}"

# Testar o simulador
puts "\n🎯 TESTANDO CÁLCULOS DE FORÇA:"
puts "-" * 30

simulator = MatchSimulatorService.new(nil)
simulator.instance_variable_set(:@home_club, club)

# Testar método de mapeamento de posições
puts "\n📍 Mapeamento de posições para #{lineup.formation}:"
attack_positions = simulator.send(:get_attack_positions_for_formation, lineup.formation)
midfield_positions = simulator.send(:get_midfield_positions_for_formation, lineup.formation)
defense_positions = simulator.send(:get_defense_positions_for_formation, lineup.formation)

puts "⚔️  Ataque: #{attack_positions.join(', ')}"
puts "🏃 Meio: #{midfield_positions.join(', ')}"
puts "🛡️  Defesa: #{defense_positions.join(', ')}"

# Testar modificadores táticos
modifiers = simulator.send(:calculate_formation_modifiers, lineup.formation)
puts "\n📊 Modificadores táticos:"
puts "🛡️  Defesa: #{(modifiers[:defense] * 100).round(1)}%"
puts "🏃 Meio: #{(modifiers[:midfield] * 100).round(1)}%"
puts "⚔️  Ataque: #{(modifiers[:attack] * 100).round(1)}%"

# Testar cálculos de força
begin
  attack_strength = simulator.send(:calculate_attack_strength_from_lineup, lineup)
  midfield_strength = simulator.send(:calculate_midfield_strength_from_lineup, lineup)
  defense_strength = simulator.send(:calculate_defense_strength_from_lineup, lineup)

  puts "\n💪 FORÇA BRUTA (antes dos modificadores):"
  puts "⚔️  Ataque: #{attack_strength.round(1)}"
  puts "🏃 Meio: #{midfield_strength.round(1)}"
  puts "🛡️  Defesa: #{defense_strength.round(1)}"

  # Aplicar modificadores
  final_attack = (attack_strength * modifiers[:attack]).round(1)
  final_midfield = (midfield_strength * modifiers[:midfield]).round(1)
  final_defense = (defense_strength * modifiers[:defense]).round(1)

  puts "\n🎯 FORÇA FINAL (com modificadores táticos):"
  puts "⚔️  Ataque: #{final_attack}"
  puts "🏃 Meio: #{final_midfield}"
  puts "🛡️  Defesa: #{final_defense}"

  total_strength = final_attack + final_midfield + final_defense
  puts "💯 Total: #{total_strength.round(1)}"

  puts "\n✅ SISTEMA TÁTICO FUNCIONANDO CORRETAMENTE!"

rescue => e
  puts "\n❌ ERRO no sistema tático:"
  puts e.message
  puts e.backtrace.first(5).join("\n")
end

puts "\n" + "=" * 50
puts "🏁 Teste concluído!"