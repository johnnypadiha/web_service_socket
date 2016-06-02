class CreateMedida < ActiveRecord::Migration
  def change
    create_table :medidas do |t|
      t.string :codigo_medida
      t.string :nome_medida
      t.integer :equipamento_id

      t.timestamps null: false
    end
  end
end
