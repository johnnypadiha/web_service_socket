class CreateTelemetria < ActiveRecord::Migration
  def change
    create_table :telemetria do |t|
      t.integer :codigo
      t.string :firmware
      t.string :ip
      t.string :periodico
      t.string :nivel_sinal

      t.timestamps null: false
    end
  end
end
