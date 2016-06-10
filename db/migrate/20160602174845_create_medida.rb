class CreateMedida < ActiveRecord::Migration
  def change
    create_table :medidas do |t|
      t.string :codigo_medida
      t.string :nome_medida
      t.integer :equipamento_id
      t.integer :timer
      t.integer :estado_normal

      t.timestamps null: true
    end
  end
end
