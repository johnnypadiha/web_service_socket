class Telemetria < ActiveRecord::Base
  self.table_name = 'main.telemetrias'

  has_many :equipamentos
end
