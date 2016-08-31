class Saida < ActiveRecord::Base
  self.table_name = "main.saidas"

  def self.check_out cancelado, data_processamento, modelo_id, aguardando
    Saida.where('cancelado = ? and data_processamento is ? and modelo_id = ? and aguardando = ?', false, nil, 1, false).first
  end
end
