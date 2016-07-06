class Status < ActiveRecord::Base
  self.table_name = 'main.status'
  has_many :eventos
  has_many :equipamentos
end
