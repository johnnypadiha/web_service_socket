class SaidaFaixaAnalogica < ActiveRecord::Base
  self.table_name = "main.saida_faixa_analogicas"

  belongs_to :saida_analogicas

end
