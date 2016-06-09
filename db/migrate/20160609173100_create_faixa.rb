class CreateFaixa < ActiveRecord::Migration
  def change
    create_table :faixas do |t|
      t.string :medida_id
      t.string :minimo
      t.integer :maximo

      t.timestamps null: false
    end
  end
end
