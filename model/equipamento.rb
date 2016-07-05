class Equipamento < ActiveRecord::Base
  self.table_name = 'main.equipamentos'

  belongs_to :telemetria

  has_many :equipamentos_codigos

  has_many :codigos,
          class_name: "Codigo",
          :through => :equipamentos_codigos
end
