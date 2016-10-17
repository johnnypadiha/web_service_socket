class Equipamento < ActiveRecord::Base
  self.table_name = 'main.equipamentos'

  has_many :medidas

  belongs_to :telemetria

  has_many :equipamentos_codigos

  has_many :codigos,
          class_name: "Codigo",
          :through => :equipamentos_codigos


  def medidas_equipamento(evento)
    event = []
    evento.each do |key, value|
      medida = Medida.includes(:faixas).where(id_local: CODIGOS_MEDIDAS.key(key.to_s)).where(equipamento_id: self.id).last

      event << medida if medida.present?
    end

    event
  end

  def process_saida_virtual
    saidas =
      telemetria.saidas
                .where(telemetria_id: telemetria_id)
                .where(comando: 4)
                .where(processado: false)
                .where(modelo_id: MODELO_ANALOGICO)
                .where(faixa_virtual: true)
                .where(data_processamento: nil)

    if saidas.present?
      saidas.update_all(processado: true, data_processamento: Time.now)
    end
  end
end
