class Faixa < ActiveRecord::Base
  self.table_name = 'main.faixas'

  belongs_to :medidas
end
