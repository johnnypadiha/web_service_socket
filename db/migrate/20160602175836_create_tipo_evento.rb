class CreateTipoEvento < ActiveRecord::Migration
  def change
    create_table :tipo_eventos do |t|
      t.integer :codigo
      t.string :nome

      t.timestamps null: false
    end
  end
end
