class SaidasAnalogica < ActiveRecord::Base
  self.table_name = "main.saida_analogicas"

  has_many = :saida_faixa_analogicas

end
