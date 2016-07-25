class MedidasEvento < ActiveRecord::Base
  self.table_name = "main.medidas_eventos"
  belongs_to :evento
  belongs_to :medida

  def self.persistir_medidas_evento(evento, medidas, equipamento = 1)

    telemetria = Telemetria.find_by_codigo(medidas[:codigo_telemetria].to_i)

    medidas[:leituras].each do |key,value|
      medida = Medida.where(id_local: key).where(equipamento_id: telemetria.id).first


      MedidasEvento.create(valor: value, medidas_id: medida.id, eventos_id: evento.id, reporte_medidas_id: 1, faixa_id: 1, nome_medida: medida.nome_medida)
    end
  end

  def self.obter_ultimas_medidas_evento(medidas_eventos_colecao, equipamento_id)
    medidas = []
    MedidasEvento.transaction do
      medidas_eventos_colecao.each do |medida_evento|
        result = MedidasEvento.where(medida_id: medida_evento[:medida_id]).last

        medidas << result if result.present?
      end
    end
    medidas
  end
end
