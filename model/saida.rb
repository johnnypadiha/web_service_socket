class Saida < ActiveRecord::Base
  self.table_name = "main.saidas"

  belongs_to :telemetria
  has_many :saida_faixas
  def self.check_out cancelado, data_processamento, modelo_id, aguardando
    Saida.where(cancelado: false)
         .where(data_processamento: nil)
         .where(modelo_id: 1)
         .where(aguardando: false)
         .where(faixa_virtual: false)
         .where('tentativas <= ?', LIMITE_TENTATIVAS)
         .first
  end
end
