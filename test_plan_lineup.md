# Plano de Testes Detalhado - Sistema de Escalação Avançado
# FutSim - Cobertura de Testes Automatizados

## 📋 Estrutura do Plano de Testes

### **Organização por Funcionalidade**
```
test/
├── integration/
│   ├── lineup_manual_selection_test.rb
│   ├── lineup_auto_selection_test.rb
│   ├── lineup_compatibility_test.rb
│   ├── lineup_formations_test.rb
│   └── lineup_chemistry_test.rb
├── system/ (End-to-End)
│   ├── lineup_user_journey_test.rb
│   ├── lineup_visual_indicators_test.rb
│   └── lineup_performance_test.rb
└── support/
    ├── lineup_test_helper.rb
    └── lineup_fixtures.rb
```

## 🧪 Testes de Integração (70% da cobertura)

### **TEST-INT-001: Seleção Manual de Jogadores**

**Objetivo**: Validar seleção/deseleção manual com todas as regras de negócio

**Cenários de Teste**:

#### **TC001.1: Seleção básica de jogador**
```ruby
def test_can_select_single_player
  # Arrange: Clube com jogadores disponíveis
  # Act: POST /clubs/:id/lineup com player_id
  # Assert: Jogador marcado como starter, contador 1/11
end
```

#### **TC001.2: Limite de 11 jogadores**
```ruby
def test_cannot_exceed_eleven_players
  # Arrange: 11 jogadores já selecionados
  # Act: Tentar selecionar 12º jogador
  # Assert: Erro retornado, contador permanece 11/11
end
```

#### **TC001.3: Deseleção de jogador**
```ruby
def test_can_deselect_player
  # Arrange: Jogador já selecionado
  # Act: Clicar novamente no jogador
  # Assert: Jogador desmarcado, contador decrementado
end
```

#### **TC001.4: Estado persistente**
```ruby
def test_selection_persists_across_requests
  # Arrange: Jogadores selecionados
  # Act: Navegar para outra página e voltar
  # Assert: Seleção mantida, contador correto
end
```

### **TEST-INT-002: Seleção Automática Inteligente**

**Objetivo**: Validar algoritmo de seleção automática com todos os critérios

#### **TC002.1: Seleção com elenco completo**
```ruby
def test_auto_select_with_full_squad
  # Arrange: Clube com 20+ jogadores em todas posições
  # Act: Clicar "Auto Selecionar Melhores"
  # Assert: 11 jogadores selecionados, formação mantida
end
```

#### **TC002.2: Seleção com elenco limitado**
```ruby
def test_auto_select_with_limited_squad
  # Arrange: Clube com poucos jogadores (13-15)
  # Act: Executar seleção automática
  # Assert: 11 jogadores selecionados, posições adaptadas
end
```

#### **TC002.3: Priorização por overall**
```ruby
def test_prioritizes_higher_overall_players
  # Arrange: Múltiplos jogadores na mesma posição
  # Act: Seleção automática
  # Assert: Jogadores com maior overall selecionados primeiro
end
```

#### **TC002.4: Fallback de formação**
```ruby
def test_formation_fallback_when_needed
  # Arrange: Elenco incompatível com formação selecionada
  # Act: Seleção automática
  # Assert: Formação adaptada, mensagem exibida
end
```

### **TEST-INT-003: Sistema de Compatibilidade**

**Objetivo**: Validar matriz de compatibilidade e penalidades

#### **TC003.1: Compatibilidade básica**
```ruby
def test_position_compatibility_matrix
  # Arrange: Jogador CDM, precisa de CB
  # Act: Sistema seleciona CDM para CB
  # Assert: Penalidade de -3 aplicada corretamente
end
```

#### **TC003.2: Penalidades por distância**
```ruby
def test_penalty_by_position_distance
  # Arrange: Diferentes combinações de posições
  # Act: Calcular penalidades
  # Assert: Penalidades corretas (-2 a -6)
end
```

#### **TC003.3: Fallback em cascata**
```ruby
def test_cascading_position_fallback
  # Arrange: Sem jogadores na posição ideal
  # Act: Sistema busca posições compatíveis
  # Assert: Melhor alternativa selecionada
end
```

### **TEST-INT-004: Formações Adaptativas**

**Objetivo**: Validar sistema de formações com fallback inteligente

#### **TC004.1: Todas as formações válidas**
```ruby
def test_all_formations_valid_structure
  formations = ['4-4-2', '4-3-3', '5-3-2', '4-5-1', '3-4-3', '4-2-3-1']
  formations.each do |formation|
    # Assert: Formação soma exatamente 11 jogadores
  end
end
```

#### **TC004.2: Viabilidade de formação**
```ruby
def test_formation_viability_calculation
  # Arrange: Elenco com composição específica
  # Act: Testar viabilidade de cada formação
  # Assert: Percentual de viabilidade correto
end
```

#### **TC004.3: Cadeia de fallback**
```ruby
def test_formation_fallback_chain
  # Arrange: Formação 3-4-3 impossível
  # Act: Sistema executa fallback
  # Assert: Testa 4-3-3, depois 4-4-2, etc.
end
```

### **TEST-INT-005: Sistema de Química**

**Objetivo**: Validar cálculos de química e bônus por atributos

#### **TC005.1: Cálculo de adequação**
```ruby
def test_stat_match_calculation
  # Arrange: Jogador com stats específicos
  # Act: Calcular adequação para posição
  # Assert: Ratio de adequação correto
end
```

#### **TC005.2: Bônus de química**
```ruby
def test_chemistry_bonus_application
  # Arrange: Jogador ideal para posição (stats 80%+)
  # Act: Sistema calcula química
  # Assert: Bônus de +2 aplicado
end
```

#### **TC005.3: Redução de penalidade**
```ruby
def test_penalty_reduction_with_good_stats
  # Arrange: Jogador fora de posição mas com stats adequados
  # Act: Sistema calcula penalidade final
  # Assert: Penalidade reduzida em 1 ponto
end
```

## 🌐 Testes End-to-End (20% da cobertura)

### **TEST-E2E-001: Jornada Completa do Usuário**

**Objetivo**: Simular experiência real do usuário do início ao fim

#### **TC101.1: Fluxo completo de escalação**
```ruby
def test_complete_lineup_flow
  visit club_lineup_path(@club)

  # 1. Verificar carregamento inicial
  assert_text "0/11"
  assert_text "Fluminense - Escalações"

  # 2. Seleção manual
  click_on first_goalkeeper
  assert_text "1/11"

  # 3. Seleção automática
  click_button "Auto Selecionar Melhores"
  assert_text "11/11"

  # 4. Verificar indicadores visuais
  assert_selector ".out-of-position-indicator", count: 7
  assert_selector ".chemistry-bonus-indicator", count: 1

  # 5. Salvar escalação
  click_button "Salvar Escalação"
  assert_text "Escalação salva com sucesso"
end
```

#### **TC101.2: Troca de formação dinâmica**
```ruby
def test_formation_change_flow
  visit club_lineup_path(@club)

  # Auto-selecionar em 4-4-2
  click_button "Auto Selecionar Melhores"
  assert_text "11/11"

  # Mudar para 4-3-3
  select "4-3-3 - Ofensiva (+15% Ataque)", from: "formation"

  # Re-executar seleção
  click_button "Auto Selecionar Melhores"

  # Verificar adaptação
  assert_text "11/11"
  # Verificar nova distribuição de jogadores
end
```

### **TEST-E2E-002: Indicadores Visuais**

**Objetivo**: Validar todos os elementos visuais e interações

#### **TC102.1: Indicadores de posição**
```ruby
def test_visual_position_indicators
  visit club_lineup_path(@club)
  click_button "Auto Selecionar Melhores"

  # Verificar indicador de fora de posição
  warning_indicators = page.all(".out-of-position-indicator")
  assert warning_indicators.count >= 5

  # Verificar indicador de química
  chemistry_indicators = page.all(".chemistry-bonus-indicator")
  assert chemistry_indicators.count >= 1

  # Verificar animação pulse
  chemistry_indicators.first.assert_matches_css("animation", /pulse/)
end
```

#### **TC102.2: Tooltips informativos**
```ruby
def test_informative_tooltips
  visit club_lineup_path(@club)
  click_button "Auto Selecionar Melhores"

  # Hover sobre indicador de fora de posição
  warning_indicator = page.find(".out-of-position-indicator", match: :first)
  warning_indicator.hover

  # Verificar tooltip aparece
  tooltip = page.find(".position-tooltip")
  assert tooltip.visible?
  assert tooltip.has_text?("Penalidade:")
  assert tooltip.has_text?("→") # Seta de mudança de posição

  # Verificar tooltip de química
  chemistry_indicator = page.find(".chemistry-bonus-indicator", match: :first)
  chemistry_indicator.hover

  chemistry_tooltip = page.find(".position-tooltip")
  assert chemistry_tooltip.has_text?("Química Excelente")
  assert chemistry_tooltip.has_text?("Bônus: +")
end
```

### **TEST-E2E-003: Performance**

**Objetivo**: Validar performance percebida pelo usuário

#### **TC103.1: Tempo de carregamento**
```ruby
def test_page_load_performance
  start_time = Time.current
  visit club_lineup_path(@club)

  # Aguardar Stimulus conectar
  assert_selector "[data-controller='lineup']"

  load_time = Time.current - start_time
  assert load_time < 2.seconds, "Página carregou em #{load_time}s (limite: 2s)"
end
```

#### **TC103.2: Performance da seleção automática**
```ruby
def test_auto_selection_performance
  visit club_lineup_path(@club)

  start_time = Time.current
  click_button "Auto Selecionar Melhores"

  # Aguardar conclusão (modal aparece)
  accept_alert "Melhores jogadores selecionados automaticamente!"

  selection_time = Time.current - start_time
  assert selection_time < 1.second, "Seleção levou #{selection_time}s (limite: 1s)"

  # Verificar resultado
  assert_text "11/11"
end
```

#### **TC103.3: Responsividade mobile**
```ruby
def test_mobile_responsiveness
  # Simular viewport mobile
  page.driver.browser.manage.window.resize_to(375, 667)

  visit club_lineup_path(@club)

  # Verificar elementos essenciais visíveis
  assert_selector "h1", text: "Escalações"
  assert_selector ".player-card", count: 28
  assert_button "Auto Selecionar Melhores"

  # Testar interação touch
  first_player = page.find(".player-card", match: :first)
  first_player.click

  assert_text "1/11"
end
```

## 🔧 Setup dos Testes

### **Configuração Base**
```ruby
# test/test_helper.rb
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'capybara/rails'
require 'capybara/minitest'

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  # Chrome headless para JavaScript
  Capybara.register_driver :headless_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  Capybara.javascript_driver = :headless_chrome
  Capybara.default_max_wait_time = 5
end
```

### **Fixtures e Helpers**
```ruby
# test/support/lineup_test_helper.rb
module LineupTestHelper
  def create_test_club_with_full_squad
    club = clubs(:fluminense)

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

  def create_player(club:, position:, overall: 75)
    # Criar jogador com atributos realistas baseados na posição
    # Lógica de criação de atributos específicos por posição
  end
end
```

## 📊 Métricas e Relatórios

### **Coverage Target**
- **Integration Tests**: 95% das funcionalidades críticas
- **End-to-End Tests**: 85% dos fluxos principais
- **Performance Tests**: 100% dos cenários críticos

### **Automation Pipeline**
```yaml
# .github/workflows/lineup_tests.yml
name: Lineup System Tests

on: [push, pull_request]

jobs:
  integration_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Integration Tests
        run: rails test:integration

  e2e_tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Chrome
        uses: browser-actions/setup-chrome@latest
      - name: Run E2E Tests
        run: rails test:system

  performance_tests:
    runs-on: ubuntu-latest
    steps:
      - name: Run Performance Tests
        run: rails test:performance
```

---

**Próximo passo**: Implementar os testes de integração começando pela seleção manual de jogadores.