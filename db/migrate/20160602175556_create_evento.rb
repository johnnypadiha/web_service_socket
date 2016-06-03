class CreateEvento < ActiveRecord::Migration
  def change
    create_table :eventos do |t|
      t.integer :tipo_eventos_id
      t.integer :telemetrias_id
      t.boolean :reporte_faixa, default: true
      t.boolean :reporte_energia, default: false
      t.boolean :reporte_sinal, default: false
      t.boolean :reporte_temperatura, default:false

      t.timestamps null: false
    end
  end
end
