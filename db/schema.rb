# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160602182155) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "eventos", force: :cascade do |t|
    t.integer "tipo_eventos_id"
    t.integer "telemetrias_id"
    t.boolean "reporte_faixa",       default: true
    t.boolean "reporte_energia",     default: false
    t.boolean "reporte_sinal",       default: false
    t.boolean "reporte_temperatura", default: false
  end

  create_table "medidas", force: :cascade do |t|
    t.string   "codigo_medida"
    t.string   "nome_medida"
    t.integer  "equipamento_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "medidas_eventos", force: :cascade do |t|
    t.integer "medidas_id"
    t.integer "eventos_id"
    t.integer "reporte_medidas_id"
    t.integer "faixa_id"
    t.string  "nome_medida"
    t.string  "valor"
  end

  create_table "raws", force: :cascade do |t|
    t.string   "pacote"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "saidas", force: :cascade do |t|
    t.boolean  "deleted"
    t.boolean  "cancelado"
    t.string   "codigo_equipamento"
    t.date     "data_processamento"
    t.string   "tentativa"
    t.string   "tipo_comando"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "tipo_eventos", force: :cascade do |t|
    t.integer "codigo"
    t.string  "nome"
  end

end
