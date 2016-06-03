class Evento < ActiveRecord::Base
  belongs_to :tipo_evento
  #belongs_to :telemetria
  has_many :medidas_eventos

  def self.persistir_evento(medidas)
    telemetria = 1
    tipo_evento = TipoEvento.tipo_evento medidas[:tipo_pacote]
    evento = Evento.create(tipo_eventos_id: tipo_evento.id, telemetrias_id: telemetria)

    MedidasEvento.persistir_medidas_evento(evento, medidas)
  end
end
