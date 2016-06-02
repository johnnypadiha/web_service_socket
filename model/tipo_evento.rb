class TipoEvento < ActiveRecord::Base
  has_many :eventos

  def self.tipo_evento codigo

    tipo_evento = TipoEvento.find_by_codigo(codigo)
  end
end
