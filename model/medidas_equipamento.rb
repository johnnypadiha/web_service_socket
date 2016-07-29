class MedidasEquipamento < ActiveRecord::Base
  self.table_name = 'main.medidas_equipamentos'

  belongs_to :medida
  belongs_to :equipamento
  #code
end
