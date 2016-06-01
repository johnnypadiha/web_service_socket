class CreateRaw < ActiveRecord::Migration
  def change
    create_table :raws do |t|
      t.string :pacote

      t.timestamps null: false
    end
  end
end
