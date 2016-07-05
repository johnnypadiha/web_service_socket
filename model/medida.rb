class Medida < ActiveRecord::Base
  self.table_name = 'main.medidas'

  has_many :medidas_eventos
end
