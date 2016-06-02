class MedidasEvento < ActiveRecord::Base
  belongs_to :evento
  belongs_to :medida
  #belongs_to :reporte_medida
end
