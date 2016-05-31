class CreateSaida < ActiveRecord::Migration
  def change
    create_table :saidas do |t|
      t.boolean :deleted
      t.boolean :cancelado
      t.string :codigo_equipamento
      t.date :data_processamento
      t.string :tentativa
      t.string :tipo_comando

      t.timestamps null: false
    end
  end
end
