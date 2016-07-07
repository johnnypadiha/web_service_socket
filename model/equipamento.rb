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
      medida = Medida.includes(:faixas).where(codigo_medida: key.to_s).where(equipamento_id: self.id).last

      event << medida if medida.present?
    end

    event
  end
end
