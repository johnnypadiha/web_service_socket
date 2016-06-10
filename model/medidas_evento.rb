class MedidasEvento < ActiveRecord::Base
  belongs_to :evento
  belongs_to :medida
  #belongs_to :reporte_medida

  def self.persistir_medidas_evento(evento, medidas, equipamento = 1)

    telemetria = Telemetria.find_by_codigo(medidas[:codigo_telemetria].to_i)

    p medidas[:leituras]

    medidas[:leituras].each do |key,value|
      medida = Medida.where(codigo_medida: key).where(equipamento_id: telemetria.id).first


      MedidasEvento.create(valor: value, medidas_id: medida.id, eventos_id: evento.id, reporte_medidas_id: 1, faixa_id: 1, nome_medida: medida.nome_medida)
    end
  end
end
