class Saida < ActiveRecord::Base
  self.table_name = "main.saidas"

  def self.check_out cancelado, data_processamento, modelo_id, aguardando
    saidas = Saida.where('cancelado = ? and data_processamento is ? and modelo_id = ? and aguardando = ?', false, nil, 1, false).pluck(:telemetria_id)

    saidas = saidas.uniq

    total_saidas = []
    saidas.each do |saida|
      total_saidas << Saida.where('cancelado = ? and data_processamento is ? and modelo_id = ? and aguardando = ? and telemetria_id = ?', false, nil, 1, false, saida).first
    end

    total_saidas.compact
  end
end
