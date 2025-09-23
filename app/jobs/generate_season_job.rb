class GenerateSeasonJob < ApplicationJob
  queue_as :default

  def perform(room_id, season_year = Date.current.year)
    Rails.logger.info "Iniciando geração de temporada em background para room #{room_id}"

    room = Room.find(room_id)

    # Verificar se já existe temporada
    if room.rounds.any?
      Rails.logger.warn "Room #{room_id} já possui rodadas, cancelando geração"
      return
    end

    # Gerar temporada completa
    result = SeasonGeneratorService.new(room, season_year).generate_complete_season!

    # Marcar como pronta
    room.update!(season_status: 'ready')

    Rails.logger.info "Temporada gerada com sucesso para room #{room_id}: #{result}"

    # Notificar usuários via ActionCable (opcional)
    # ActionCable.server.broadcast(
    #   "room_#{room_id}",
    #   {
    #     type: 'season_generated',
    #     message: "Temporada gerada! #{result[:total_rounds]} rodadas criadas.",
    #     data: result
    #   }
    # )

  rescue => e
    Rails.logger.error "Erro ao gerar temporada para room #{room_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Marcar como erro
    room = Room.find(room_id)
    room.update!(season_status: 'failed')

    # Aqui você pode notificar o erro via ActionCable ou email
    # ActionCable.server.broadcast(
    #   "room_#{room_id}",
    #   {
    #     type: 'season_generation_failed',
    #     message: "Erro ao gerar temporada: #{e.message}"
    #   }
    # )

    raise e # Re-raise para o ActiveJob tentar novamente
  end
end