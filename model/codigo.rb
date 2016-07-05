class Codigo < ActiveRecord::Base
  self.table_name = 'main.codigos'
  has_many :equipamentos_codigos
  has_many :equipamentos,
            class_name: "Equipamento",
            :through => :equipamentos_codigos

end
