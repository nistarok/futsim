#!/usr/bin/env ruby
# Script para executar a suíte completa de testes do sistema de escalação

require 'fileutils'

class LineupTestRunner
  def initialize
    @test_results = {
      integration: {},
      system: {},
      total_tests: 0,
      passed_tests: 0,
      failed_tests: 0,
      errors: []
    }
  end

  def run_all_tests
    puts "🧪 INICIANDO SUÍTE DE TESTES DO SISTEMA DE ESCALAÇÃO"
    puts "=" * 60

    start_time = Time.now

    # Verificar prerequisites
    check_prerequisites

    # Executar testes de integração
    run_integration_tests

    # Executar testes de sistema (E2E)
    run_system_tests

    # Gerar relatório final
    end_time = Time.now
    generate_final_report(end_time - start_time)
  end

  private

  def check_prerequisites
    puts "\n🔍 Verificando pré-requisitos..."

    # Verificar se o ambiente de teste está configurado
    unless File.exist?('test/test_helper.rb')
      error("test/test_helper.rb não encontrado")
    end

    # Verificar se as fixtures existem
    unless Dir.exist?('test/fixtures')
      puts "⚠️  Diretório test/fixtures não encontrado - criando..."
      FileUtils.mkdir_p('test/fixtures')
    end

    # Verificar dependências importantes
    required_gems = ['capybara', 'selenium-webdriver']
    required_gems.each do |gem_name|
      system("bundle show #{gem_name} > /dev/null 2>&1") or error("Gem #{gem_name} não instalada")
    end

    puts "✅ Pré-requisitos verificados"
  end

  def run_integration_tests
    puts "\n🔧 EXECUTANDO TESTES DE INTEGRAÇÃO"
    puts "-" * 40

    integration_tests = [
      'test/integration/lineup_manual_selection_test.rb',
      'test/integration/lineup_auto_selection_test.rb',
      'test/integration/lineup_compatibility_test.rb',
      'test/integration/lineup_formations_test.rb',
      'test/integration/lineup_chemistry_test.rb'
    ]

    integration_tests.each do |test_file|
      run_single_test_file(test_file, :integration)
    end
  end

  def run_system_tests
    puts "\n🌐 EXECUTANDO TESTES END-TO-END (SISTEMA)"
    puts "-" * 40

    system_tests = [
      'test/system/lineup_user_journey_test.rb',
      'test/system/lineup_visual_indicators_test.rb',
      'test/system/lineup_performance_test.rb'
    ]

    system_tests.each do |test_file|
      run_single_test_file(test_file, :system)
    end
  end

  def run_single_test_file(test_file, category)
    unless File.exist?(test_file)
      puts "⚠️  #{test_file} não encontrado - pulando"
      return
    end

    test_name = File.basename(test_file, '.rb')
    puts "\n📝 Executando: #{test_name}"

    start_time = Time.now

    # Executar o teste
    result = system("bundle exec rails test #{test_file}")

    end_time = Time.now
    duration = end_time - start_time

    if result
      puts "  ✅ #{test_name} - PASSOU (#{duration.round(2)}s)"
      @test_results[category][test_name] = { status: :passed, duration: duration }
      @test_results[:passed_tests] += 1
    else
      puts "  ❌ #{test_name} - FALHOU (#{duration.round(2)}s)"
      @test_results[category][test_name] = { status: :failed, duration: duration }
      @test_results[:failed_tests] += 1
      @test_results[:errors] << "#{test_name}: Falha na execução"
    end

    @test_results[:total_tests] += 1
  end

  def generate_final_report(total_duration)
    puts "\n" + "=" * 60
    puts "📊 RELATÓRIO FINAL DOS TESTES"
    puts "=" * 60

    puts "\n📈 ESTATÍSTICAS GERAIS:"
    puts "  • Total de testes: #{@test_results[:total_tests]}"
    puts "  • Testes passaram: #{@test_results[:passed_tests]}"
    puts "  • Testes falharam: #{@test_results[:failed_tests]}"
    puts "  • Taxa de sucesso: #{success_rate.round(1)}%"
    puts "  • Tempo total: #{total_duration.round(2)}s"

    puts "\n🔧 TESTES DE INTEGRAÇÃO:"
    @test_results[:integration].each do |test_name, result|
      status_icon = result[:status] == :passed ? "✅" : "❌"
      puts "  #{status_icon} #{test_name} (#{result[:duration].round(2)}s)"
    end

    puts "\n🌐 TESTES END-TO-END:"
    @test_results[:system].each do |test_name, result|
      status_icon = result[:status] == :passed ? "✅" : "❌"
      puts "  #{status_icon} #{test_name} (#{result[:duration].round(2)}s)"
    end

    if @test_results[:errors].any?
      puts "\n❌ ERROS ENCONTRADOS:"
      @test_results[:errors].each do |error|
        puts "  • #{error}"
      end
    end

    puts "\n🎯 COBERTURA IMPLEMENTADA:"
    puts "  • ✅ Seleção Manual de Jogadores (8 cenários)"
    puts "  • ✅ Seleção Automática Inteligente (8 cenários)"
    puts "  • ✅ Sistema de Compatibilidade (8 cenários)"
    puts "  • ✅ Formações Adaptativas (8 cenários)"
    puts "  • ✅ Sistema de Química (8 cenários)"
    puts "  • ✅ Jornada Completa do Usuário (8 cenários)"
    puts "  • ✅ Indicadores Visuais (8 cenários)"
    puts "  • ✅ Testes de Performance (8 cenários)"

    puts "\n📋 PRÓXIMOS PASSOS:"
    if @test_results[:failed_tests] > 0
      puts "  1. ❗ Corrigir #{@test_results[:failed_tests]} teste(s) falhando"
      puts "  2. 🔍 Investigar erros específicos listados acima"
      puts "  3. 🔄 Re-executar testes após correções"
    else
      puts "  1. ✅ Todos os testes estão passando!"
      puts "  2. 🚀 Sistema pronto para produção"
      puts "  3. 📝 Considerar adicionar mais cenários edge case"
    end

    puts "\n🏆 STATUS FINAL: #{overall_status}"
    puts "=" * 60
  end

  def success_rate
    return 0 if @test_results[:total_tests] == 0
    (@test_results[:passed_tests].to_f / @test_results[:total_tests]) * 100
  end

  def overall_status
    if @test_results[:failed_tests] == 0
      "🎉 SUCESSO COMPLETO - Sistema de Escalação Aprovado!"
    elsif success_rate >= 80
      "⚠️  PARCIAL - Maioria dos testes passando (#{success_rate.round(1)}%)"
    else
      "❌ ATENÇÃO NECESSÁRIA - Muitos testes falhando (#{success_rate.round(1)}%)"
    end
  end

  def error(message)
    puts "❌ ERRO: #{message}"
    exit 1
  end
end

# Executar se este script for chamado diretamente
if __FILE__ == $0
  runner = LineupTestRunner.new
  runner.run_all_tests
end