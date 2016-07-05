class EquipamentosCodigo < ActiveRecord::Base
  self.table_name = 'main.equipamentos_codigos'

  belongs_to :equipamento
  belongs_to :codigo
end
