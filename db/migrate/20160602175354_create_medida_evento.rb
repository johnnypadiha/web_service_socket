class CreateMedidaEvento < ActiveRecord::Migration
  def change
    create_table :medidas_eventos do |t|
      t.integer :medidas_id
      t.integer :eventos_id
      t.integer :reporte_medidas_id
      t.integer :faixa_id
      t.string :nome_medida
      t.string :valor

      t.timestamps null: false
    end
  end
end
