class SaidaFaixas < ActiveRecord::Base
  self.table_name = "main.saida_faixas"
  belongs_to :saida
end
