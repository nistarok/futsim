import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "startersCount",
    "formationDescription",
    "formationSelect",
    "playerCard",
    "autoSelectButton",
    "clearLineupButton"
  ]

  static values = {
    maxStarters: { type: Number, default: 11 },
    clubPrimaryColor: String
  }

  connect() {
    console.log("Lineup controller connected")
    this.selectedPlayers = new Set()
    this.updateStartersCount()
    this.updateFormationDescription()
    this.setupCompatiblePositions()
  }

  // Define positions compatibility and penalties
  setupCompatiblePositions() {
    this.compatiblePositions = {
      'GK': [
        { position: 'GK', penalty: 0 }
      ],
      'CB': [
        { position: 'CB', penalty: 0 },
        { position: 'CDM', penalty: -3 }, // Zagueiro pode jogar de volante
        { position: 'LB', penalty: -5 }, // Zagueiro pode jogar de lateral (menos ideal)
        { position: 'RB', penalty: -5 }
      ],
      'LB': [
        { position: 'LB', penalty: 0 },
        { position: 'LM', penalty: -3 }, // Lateral pode jogar de meia lateral
        { position: 'CB', penalty: -4 }, // Lateral pode voltar para zagueiro
        { position: 'CDM', penalty: -6 }
      ],
      'RB': [
        { position: 'RB', penalty: 0 },
        { position: 'RM', penalty: -3 }, // Lateral pode jogar de meia lateral
        { position: 'CB', penalty: -4 }, // Lateral pode voltar para zagueiro
        { position: 'CDM', penalty: -6 }
      ],
      'CDM': [
        { position: 'CDM', penalty: 0 },
        { position: 'CM', penalty: -2 }, // Volante pode jogar de meio-campo
        { position: 'CB', penalty: -4 }, // Volante pode jogar de zagueiro
        { position: 'CAM', penalty: -5 }
      ],
      'CM': [
        { position: 'CM', penalty: 0 },
        { position: 'CDM', penalty: -2 }, // Meio-campo pode jogar de volante
        { position: 'CAM', penalty: -2 }, // Meio-campo pode jogar mais ofensivo
        { position: 'LM', penalty: -3 },
        { position: 'RM', penalty: -3 }
      ],
      'CAM': [
        { position: 'CAM', penalty: 0 },
        { position: 'CM', penalty: -2 }, // Meia ofensivo pode jogar mais recuado
        { position: 'LW', penalty: -4 }, // Pode jogar nas pontas
        { position: 'RW', penalty: -4 },
        { position: 'ST', penalty: -3 }  // Pode jogar de falso 9
      ],
      'LM': [
        { position: 'LM', penalty: 0 },
        { position: 'LB', penalty: -3 }, // Meia lateral pode jogar de lateral
        { position: 'LW', penalty: -2 }, // Pode jogar de ponta
        { position: 'CM', penalty: -3 }
      ],
      'RM': [
        { position: 'RM', penalty: 0 },
        { position: 'RB', penalty: -3 }, // Meia lateral pode jogar de lateral
        { position: 'RW', penalty: -2 }, // Pode jogar de ponta
        { position: 'CM', penalty: -3 }
      ],
      'LW': [
        { position: 'LW', penalty: 0 },
        { position: 'LM', penalty: -2 }, // Ponta pode jogar mais recuado
        { position: 'ST', penalty: -3 }, // Ponta pode jogar de atacante
        { position: 'CAM', penalty: -4 }
      ],
      'RW': [
        { position: 'RW', penalty: 0 },
        { position: 'RM', penalty: -2 }, // Ponta pode jogar mais recuado
        { position: 'ST', penalty: -3 }, // Ponta pode jogar de atacante
        { position: 'CAM', penalty: -4 }
      ],
      'ST': [
        { position: 'ST', penalty: 0 },
        { position: 'CAM', penalty: -3 }, // Atacante pode jogar de falso 9
        { position: 'LW', penalty: -4 }, // Atacante pode jogar nas pontas
        { position: 'RW', penalty: -4 }
      ]
    }

    // Define formation fallback system
    this.formationFallbacks = {
      '4-3-3': ['4-3-3', '4-4-2', '4-5-1', '5-3-2'],     // Ultra ofensiva → equilibrada → defensiva
      '3-4-3': ['3-4-3', '4-3-3', '4-4-2', '5-3-2'],     // Ultra ofensiva → ofensiva → equilibrada
      '4-4-2': ['4-4-2', '4-5-1', '5-3-2'],              // Equilibrada → meio-campo → defensiva
      '4-5-1': ['4-5-1', '4-4-2', '5-3-2'],              // Meio-campo → equilibrada → defensiva
      '5-3-2': ['5-3-2', '4-5-1', '4-4-2'],              // Defensiva → meio-campo → equilibrada
      '4-2-3-1': ['4-2-3-1', '4-3-3', '4-4-2', '4-5-1']  // Híbrida → ofensiva → equilibrada
    }
  }

  // Get available players for a position with compatibility system
  getPlayersForPosition(targetPosition) {
    const compatiblePositions = this.compatiblePositions[targetPosition] || []
    let availablePlayers = []

    // For each compatible position, get players and apply penalty
    compatiblePositions.forEach(({ position, penalty }) => {
      const players = document.querySelectorAll(`[data-position="${position}"]`)

      Array.from(players).forEach(playerCard => {
        const isAlreadySelected = playerCard.classList.contains('starter')
        if (isAlreadySelected) return // Skip already selected players

        const originalOverall = parseInt(playerCard.querySelector('.overall-rating').textContent)
        const playerStats = this.extractPlayerStats(playerCard)

        // Calculate advanced compatibility score
        const compatibilityData = this.calculateAdvancedCompatibility(
          position, targetPosition, originalOverall, playerStats
        )

        availablePlayers.push({
          playerCard,
          originalPosition: position,
          targetPosition,
          originalOverall,
          adjustedOverall: compatibilityData.adjustedOverall,
          penalty: compatibilityData.penalty,
          chemistryBonus: compatibilityData.chemistryBonus,
          compatibilityScore: compatibilityData.compatibilityScore,
          playerId: parseInt(playerCard.dataset.playerId)
        })
      })
    })

    // Sort by compatibility score (best compatibility first)
    return availablePlayers.sort((a, b) => b.compatibilityScore - a.compatibilityScore)
  }

  // Extract player stats from DOM
  extractPlayerStats(playerCard) {
    const statsText = playerCard.querySelector('div[style*="font-size: 0.75rem; color: #6b7280;"]').textContent
    const statsMatch = statsText.match(/F:(\d+) E:(\d+) V:(\d+) A:(\d+) D:(\d+) P:(\d+)/)

    if (!statsMatch) return { strength: 50, stamina: 50, speed: 50, attack: 50, defense: 50, passing: 50 }

    return {
      strength: parseInt(statsMatch[1]),
      stamina: parseInt(statsMatch[2]),
      speed: parseInt(statsMatch[3]),
      attack: parseInt(statsMatch[4]),
      defense: parseInt(statsMatch[5]),
      passing: parseInt(statsMatch[6])
    }
  }

  // Calculate advanced compatibility with chemistry bonuses
  calculateAdvancedCompatibility(originalPosition, targetPosition, originalOverall, stats) {
    const baseCompatibility = this.compatiblePositions[originalPosition]
      .find(pos => pos.position === targetPosition)

    let penalty = baseCompatibility ? baseCompatibility.penalty : -8 // Heavy penalty for incompatible positions
    let chemistryBonus = 0

    // Position-specific stat bonuses
    const positionStatRequirements = {
      'GK': { defense: 0.4, strength: 0.3, stamina: 0.3 },
      'CB': { defense: 0.5, strength: 0.3, stamina: 0.2 },
      'LB': { defense: 0.3, speed: 0.3, stamina: 0.2, passing: 0.2 },
      'RB': { defense: 0.3, speed: 0.3, stamina: 0.2, passing: 0.2 },
      'CDM': { defense: 0.3, passing: 0.3, stamina: 0.2, strength: 0.2 },
      'CM': { passing: 0.4, stamina: 0.3, attack: 0.15, defense: 0.15 },
      'CAM': { passing: 0.4, attack: 0.3, speed: 0.2, stamina: 0.1 },
      'LM': { speed: 0.3, passing: 0.3, stamina: 0.2, attack: 0.2 },
      'RM': { speed: 0.3, passing: 0.3, stamina: 0.2, attack: 0.2 },
      'LW': { speed: 0.4, attack: 0.4, stamina: 0.2 },
      'RW': { speed: 0.4, attack: 0.4, stamina: 0.2 },
      'ST': { attack: 0.5, speed: 0.3, strength: 0.2 }
    }

    // Calculate how well player's stats match the target position requirements
    const requirements = positionStatRequirements[targetPosition] || {}
    let statMatch = 0
    let totalWeight = 0

    Object.keys(requirements).forEach(statName => {
      const weight = requirements[statName]
      const statValue = stats[statName] || 50
      statMatch += (statValue / 100) * weight
      totalWeight += weight
    })

    const statMatchRatio = totalWeight > 0 ? statMatch / totalWeight : 0.5

    // Chemistry bonus based on stat suitability
    if (statMatchRatio >= 0.8) {
      chemistryBonus = 2 // Excellent stat match
    } else if (statMatchRatio >= 0.65) {
      chemistryBonus = 1 // Good stat match
    } else if (statMatchRatio >= 0.5) {
      chemistryBonus = 0 // Average stat match
    } else {
      chemistryBonus = -1 // Poor stat match
    }

    // Reduce penalty if player has good stats for the position
    if (originalPosition !== targetPosition && chemistryBonus >= 1) {
      penalty = Math.min(penalty + 1, -1) // Reduce penalty by 1 (but keep at least -1)
    }

    const adjustedOverall = originalOverall + penalty + chemistryBonus
    const compatibilityScore = adjustedOverall + (statMatchRatio * 5) // Boost score for better stat match

    return {
      penalty,
      chemistryBonus,
      adjustedOverall,
      compatibilityScore,
      statMatchRatio
    }
  }

  // Check if a formation is viable with available players
  isFormationViable(formationLimits, minViabilityThreshold = 0.8) {
    let totalPositionsNeeded = 0
    let totalPositionsFillable = 0

    Object.keys(formationLimits).forEach(position => {
      const needed = formationLimits[position]
      if (needed === 0) return

      const availablePlayers = this.getPlayersForPosition(position)
      const fillable = Math.min(needed, availablePlayers.length)

      totalPositionsNeeded += needed
      totalPositionsFillable += fillable
    })

    const viabilityRatio = totalPositionsFillable / totalPositionsNeeded
    console.log(`Formation viability: ${Math.round(viabilityRatio * 100)}% (${totalPositionsFillable}/${totalPositionsNeeded} positions fillable)`)

    return viabilityRatio >= minViabilityThreshold
  }

  // Find the best viable formation from fallback options
  findBestViableFormation(requestedFormation, formationLimits) {
    const fallbackOptions = this.formationFallbacks[requestedFormation] || [requestedFormation]

    for (const fallbackFormation of fallbackOptions) {
      const limits = formationLimits[fallbackFormation]
      if (!limits) continue

      console.log(`Testing formation: ${fallbackFormation}`)
      if (this.isFormationViable(limits)) {
        if (fallbackFormation !== requestedFormation) {
          console.log(`🔄 Formation fallback: ${requestedFormation} → ${fallbackFormation}`)
        }
        return { formation: fallbackFormation, limits }
      }
    }

    // If no formation is viable, return the original requested formation
    // The system will do its best with position compatibility
    console.warn(`⚠️ No viable formation found, using ${requestedFormation} with maximum compatibility`)
    return { formation: requestedFormation, limits: formationLimits[requestedFormation] }
  }

  // Toggle player selection
  togglePlayer(event) {
    event.preventDefault()

    const playerCard = event.currentTarget
    const playerId = parseInt(playerCard.dataset.playerId)
    const position = playerCard.dataset.position

    const input = playerCard.querySelector('input[type="hidden"]')
    const indicator = playerCard.querySelector('.starter-indicator')
    const isCurrentlyStarter = playerCard.classList.contains('starter')

    if (isCurrentlyStarter) {
      // Remove from starters
      this.removeStarter(playerCard, input, indicator, playerId)
    } else {
      // Add to starters (check limit)
      if (this.startersCount >= this.maxStartersValue) {
        alert('Você só pode selecionar 11 titulares!')
        return
      }
      this.addStarter(playerCard, input, indicator, playerId)
    }

    this.updateStartersCount()
  }

  // Add player as starter
  addStarter(playerCard, input, indicator, playerId) {
    playerCard.classList.add('starter')
    playerCard.style.borderColor = '#22c55e'
    playerCard.style.backgroundColor = '#f0fdf4'
    indicator.style.backgroundColor = '#22c55e'
    input.disabled = false
    this.selectedPlayers.add(playerId)
  }

  // Add out-of-position visual indicator
  addOutOfPositionIndicator(playerCard, originalPosition, targetPosition, penalty, chemistryBonus = 0) {
    // Remove any existing indicator
    this.removePositionIndicators(playerCard)

    // Create warning indicator
    const warningIndicator = document.createElement('div')
    warningIndicator.className = 'position-indicator out-of-position-indicator'
    warningIndicator.innerHTML = '⚠️'
    warningIndicator.style.cssText = `
      position: absolute;
      top: -8px;
      right: -8px;
      background: #f59e0b;
      color: white;
      border-radius: 50%;
      width: 20px;
      height: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 12px;
      font-weight: bold;
      border: 2px solid white;
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
      z-index: 10;
      cursor: help;
    `

    // Create custom tooltip
    const tooltip = this.createTooltip(originalPosition, targetPosition, penalty, chemistryBonus, 'warning')

    // Show/hide tooltip on hover
    this.setupTooltipEvents(warningIndicator, tooltip)

    // Make parent relative for positioning
    playerCard.style.position = 'relative'

    // Append elements
    warningIndicator.appendChild(tooltip)
    playerCard.appendChild(warningIndicator)

    // Add subtle border color change to indicate out-of-position
    playerCard.style.borderColor = '#f59e0b'
  }

  // Add chemistry bonus indicator
  addChemistryBonusIndicator(playerCard, chemistryBonus) {
    // Remove any existing indicator
    this.removePositionIndicators(playerCard)

    // Create bonus indicator
    const bonusIndicator = document.createElement('div')
    bonusIndicator.className = 'position-indicator chemistry-bonus-indicator'
    bonusIndicator.innerHTML = '✨'
    bonusIndicator.style.cssText = `
      position: absolute;
      top: -8px;
      right: -8px;
      background: #10b981;
      color: white;
      border-radius: 50%;
      width: 20px;
      height: 20px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 12px;
      font-weight: bold;
      border: 2px solid white;
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
      z-index: 10;
      cursor: help;
      animation: pulse-green 2s infinite;
    `

    // Add CSS animation for pulse effect
    const style = document.createElement('style')
    style.textContent = `
      @keyframes pulse-green {
        0%, 100% { transform: scale(1); box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
        50% { transform: scale(1.1); box-shadow: 0 4px 8px rgba(16, 185, 129, 0.4); }
      }
    `
    if (!document.head.querySelector('style[data-chemistry-animations]')) {
      style.setAttribute('data-chemistry-animations', 'true')
      document.head.appendChild(style)
    }

    // Create custom tooltip for chemistry bonus
    const tooltip = this.createTooltip(null, null, 0, chemistryBonus, 'bonus')

    // Show/hide tooltip on hover
    this.setupTooltipEvents(bonusIndicator, tooltip)

    // Make parent relative for positioning
    playerCard.style.position = 'relative'

    // Append elements
    bonusIndicator.appendChild(tooltip)
    playerCard.appendChild(bonusIndicator)

    // Add subtle border enhancement for chemistry bonus
    playerCard.style.boxShadow = '0 0 8px rgba(16, 185, 129, 0.3)'
  }

  // Create tooltip based on type
  createTooltip(originalPosition, targetPosition, penalty, chemistryBonus, type) {
    const tooltip = document.createElement('div')
    tooltip.className = 'position-tooltip'
    tooltip.style.cssText = `
      position: absolute;
      top: -50px;
      right: -10px;
      background: #1f2937;
      color: white;
      padding: 8px 12px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 500;
      white-space: nowrap;
      opacity: 0;
      visibility: hidden;
      transition: all 0.2s ease;
      pointer-events: none;
      z-index: 20;
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      min-width: 150px;
    `

    let content = ''
    if (type === 'warning') {
      const originalPos = this.getPositionName(originalPosition)
      const targetPos = this.getPositionName(targetPosition)
      const chemistryText = chemistryBonus > 0 ? `<div style="color: #10b981; margin-top: 2px;">Bônus Química: +${chemistryBonus}</div>` : ''
      content = `
        <div style="font-weight: 600; margin-bottom: 2px;">
          ${originalPos} → ${targetPos}
        </div>
        <div style="color: #fbbf24;">
          Penalidade: ${penalty} pontos
        </div>
        ${chemistryText}
      `
    } else if (type === 'bonus') {
      content = `
        <div style="font-weight: 600; margin-bottom: 2px; color: #10b981;">
          ✨ Química Excelente
        </div>
        <div style="color: #10b981;">
          Bônus: +${chemistryBonus} pontos
        </div>
        <div style="color: #9ca3af; margin-top: 2px; font-size: 10px;">
          Atributos ideais para a posição
        </div>
      `
    }

    tooltip.innerHTML = content

    // Add arrow to tooltip
    const arrow = document.createElement('div')
    arrow.style.cssText = `
      position: absolute;
      top: 100%;
      right: 15px;
      width: 0;
      height: 0;
      border-left: 6px solid transparent;
      border-right: 6px solid transparent;
      border-top: 6px solid #1f2937;
    `
    tooltip.appendChild(arrow)

    return tooltip
  }

  // Setup tooltip hover events
  setupTooltipEvents(indicator, tooltip) {
    indicator.addEventListener('mouseenter', () => {
      tooltip.style.opacity = '1'
      tooltip.style.visibility = 'visible'
    })

    indicator.addEventListener('mouseleave', () => {
      tooltip.style.opacity = '0'
      tooltip.style.visibility = 'hidden'
    })
  }

  // Get readable position name
  getPositionName(position) {
    const positions = {
      'GK': 'Goleiro',
      'CB': 'Zagueiro',
      'LB': 'Lateral Esq.',
      'RB': 'Lateral Dir.',
      'CDM': 'Volante',
      'CM': 'Meio-campo',
      'CAM': 'Meia Ofensivo',
      'LM': 'Meia Esquerdo',
      'RM': 'Meia Direito',
      'LW': 'Ponta Esquerda',
      'RW': 'Ponta Direita',
      'ST': 'Atacante'
    }
    return positions[position] || position
  }

  // Remove all position indicators
  removePositionIndicators(playerCard) {
    const existingIndicators = playerCard.querySelectorAll('.position-indicator')
    existingIndicators.forEach(indicator => indicator.remove())

    // Reset styling
    if (playerCard.classList.contains('starter')) {
      playerCard.style.borderColor = '#22c55e'
      playerCard.style.boxShadow = ''
    } else {
      playerCard.style.borderColor = '#e5e7eb'
      playerCard.style.boxShadow = ''
    }
  }

  // Legacy method for compatibility
  removeOutOfPositionIndicator(playerCard) {
    this.removePositionIndicators(playerCard)
  }

  // Remove player from starters
  removeStarter(playerCard, input, indicator, playerId) {
    playerCard.classList.remove('starter')
    playerCard.style.borderColor = '#e5e7eb'
    playerCard.style.backgroundColor = 'white'
    indicator.style.backgroundColor = 'white'
    input.disabled = true
    this.selectedPlayers.delete(playerId)

    // Remove position indicators when removing from starters
    this.removePositionIndicators(playerCard)
  }

  // Update formation description
  updateFormationDescription(event = null) {
    const formation = event ? event.target.value : this.formationSelectTarget.value

    const formations = {
      '4-4-2': 'Formação equilibrada com ataque e defesa balanceados',
      '4-3-3': 'Formação ofensiva com mais ataque (+15% ataque)',
      '5-3-2': 'Formação defensiva com mais defesa (+37% defesa)',
      '4-5-1': 'Formação com meio-campo forte (+10% meio-campo)',
      '3-4-3': 'Formação ultra-ofensiva com mais ataque (+15% ataque)',
      '4-2-3-1': 'Formação híbrida e balanceada (+8% defesa, +15% meio-campo)'
    }

    const description = formations[formation] || formations['4-4-2']
    this.formationDescriptionTarget.textContent = description
  }

  // Auto select best players
  autoSelect() {
    console.log("Auto selecting best players...")

    // Clear current selection
    this.clearLineup()

    // Get current formation
    const formation = this.formationSelectTarget.value

    // Define position limits based on formation
    const formationLimits = {
      '4-4-2': {
        'GK': 1,
        'CB': 2,
        'LB': 1,
        'RB': 1,
        'CDM': 2,
        'CM': 2,
        'CAM': 0,
        'LM': 0,
        'RM': 0,
        'LW': 0,
        'RW': 0,
        'ST': 2
      },
      '4-3-3': {
        'GK': 1,
        'CB': 2,
        'LB': 1,
        'RB': 1,
        'CDM': 1,
        'CM': 2,
        'CAM': 0,
        'LM': 0,
        'RM': 0,
        'LW': 1,
        'RW': 1,
        'ST': 1
      },
      '5-3-2': {
        'GK': 1,
        'CB': 3,
        'LB': 1,
        'RB': 1,
        'CDM': 1,
        'CM': 1,
        'CAM': 1,
        'LM': 0,
        'RM': 0,
        'LW': 0,
        'RW': 0,
        'ST': 2
      },
      '4-5-1': {
        'GK': 1,
        'CB': 2,
        'LB': 1,
        'RB': 1,
        'CDM': 2,
        'CM': 2,
        'CAM': 1,
        'LM': 0,
        'RM': 0,
        'LW': 0,
        'RW': 0,
        'ST': 1
      },
      '3-4-3': {
        'GK': 1,
        'CB': 3,
        'LB': 0,
        'RB': 0,
        'CDM': 0,
        'CM': 2,
        'CAM': 0,
        'LM': 1,
        'RM': 1,
        'LW': 1,
        'RW': 1,
        'ST': 1
      },
      '4-2-3-1': {
        'GK': 1,
        'CB': 2,
        'LB': 1,
        'RB': 1,
        'CDM': 2,
        'CM': 0,
        'CAM': 1,
        'LM': 1,
        'RM': 1,
        'LW': 0,
        'RW': 0,
        'ST': 1
      }
    }

    // Find the best viable formation (with fallback if needed)
    const { formation: finalFormation, limits: positionLimits } = this.findBestViableFormation(formation, formationLimits)

    // Update formation selector if we changed formation
    if (finalFormation !== formation) {
      this.formationSelectTarget.value = finalFormation
      this.updateFormationDescription()
    }

    // Smart selection with adaptive formation system
    Object.keys(positionLimits).forEach(targetPosition => {
      const limit = positionLimits[targetPosition]
      if (limit === 0) return // Skip positions not used in this formation

      let selectedCount = 0

      // Get available players for this position (including compatible positions)
      const availablePlayers = this.getPlayersForPosition(targetPosition)

      // Select best available players up to the limit
      for (const playerData of availablePlayers) {
        if (selectedCount >= limit) break

        const { playerCard, playerId, penalty } = playerData
        const input = playerCard.querySelector('input[type="hidden"]')
        const indicator = playerCard.querySelector('.starter-indicator')

        // Add visual indicators based on position compatibility and chemistry
        if (penalty < 0) {
          console.log(`Player out of position: ${playerCard.querySelector('span:nth-child(2)').textContent} (${playerData.originalPosition} → ${targetPosition}, penalty: ${penalty}, chemistry: ${playerData.chemistryBonus})`)
          this.addOutOfPositionIndicator(playerCard, playerData.originalPosition, targetPosition, penalty, playerData.chemistryBonus)
        } else if (playerData.chemistryBonus > 0) {
          console.log(`Player with chemistry bonus: ${playerCard.querySelector('span:nth-child(2)').textContent} (${playerData.originalPosition}, bonus: +${playerData.chemistryBonus})`)
          this.addChemistryBonusIndicator(playerCard, playerData.chemistryBonus)
        }

        this.addStarter(playerCard, input, indicator, playerId)
        selectedCount++
      }

      // Log if we couldn't fill all positions
      if (selectedCount < limit) {
        console.warn(`Could not fill all ${targetPosition} positions: ${selectedCount}/${limit} filled`)
      }
    })

    this.updateStartersCount()

    // Inform user about formation changes
    if (finalFormation !== formation) {
      alert(`Formação ajustada para ${finalFormation} baseada no elenco disponível. Melhores jogadores selecionados!`)
    } else {
      alert('Melhores jogadores selecionados automaticamente!')
    }
  }

  // Clear lineup
  clearLineup() {
    console.log("Clearing lineup...")

    this.playerCardTargets.forEach(playerCard => {
      if (playerCard.classList.contains('starter')) {
        const playerId = parseInt(playerCard.dataset.playerId)
        const input = playerCard.querySelector('input[type="hidden"]')
        const indicator = playerCard.querySelector('.starter-indicator')

        this.removeStarter(playerCard, input, indicator, playerId)
      }
      // Also remove any position indicators from non-starter cards
      this.removePositionIndicators(playerCard)
    })

    this.selectedPlayers.clear()
    this.updateStartersCount()
  }

  // Update starters count display
  updateStartersCount() {
    this.startersCount = document.querySelectorAll('.starter').length
    this.startersCountTarget.textContent = this.startersCount

    // Update color based on count
    const countElement = this.startersCountTarget
    if (this.startersCount === this.maxStartersValue) {
      countElement.style.color = this.clubPrimaryColorValue || '#0047AB'
    } else if (this.startersCount > this.maxStartersValue) {
      countElement.style.color = '#dc2626'
    } else {
      countElement.style.color = '#ea580c'
    }
  }
}