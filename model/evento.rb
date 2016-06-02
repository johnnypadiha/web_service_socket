class Evento < ActiveRecord::Base
  belongs_to :tipo_evento
  #belongs_to :telemetria
  has_many :medidas_eventos
end
