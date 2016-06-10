class CreateTelemetria < ActiveRecord::Migration
  def change
    create_table :telemetria do |t|
      t.integer :codigo
      t.string :firmware
      t.string :ip_primario
      t.string :ip_secundario
      t.integer :porta_ip_primario
      t.integer :porta_ip_secundario
      t.integer :operadora
      t.string :host
      t.integer :porta_dns
      t.string :periodico
      t.string :nivel_sinal

      t.timestamps null: true
    end
  end
end
