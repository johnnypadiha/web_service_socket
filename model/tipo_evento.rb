class TipoEvento < ActiveRecord::Base
  has_many :eventos
  
end
