class Evento < ActiveRecord::Base
  self.table_name = 'main.eventos'
  include Logging
  belongs_to :tipo_evento
  belongs_to :status
  #belongs_to :telemetria
  has_many :medidas_eventos

  def self.persistir_evento(medidas)
    telemetria = Telemetria.find_by_codigo(medidas[:codigo_telemetria].to_i)
    if telemetria.present?
      tipo_evento = TipoEvento.tipo_evento medidas[:tipo_pacote]
      evento = Evento.create(tipo_eventos_id: tipo_evento.id, telemetrias_id: telemetria.id, nivel_sinal: medidas[:DBM])

      MedidasEvento.persistir_medidas_evento(evento, medidas)
    else
      puts "Pacote não persistido!! A telemetria ID #{medidas[:codigo_telemetria]} Não cadastrada no sistema!".red
      logger.info "Pacote persistido!! A telemetria ID #{medidas[:codigo_telemetria]} Não cadastrada no sistema!"
    end
  end
end
