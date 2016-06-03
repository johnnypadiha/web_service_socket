require_relative '../../model/tipo_evento.rb'
class AddTipoEventosDefault < ActiveRecord::Migration
  def change
    TipoEvento.find_or_create_by(codigo: 0 ,nome: 'Periodico OK')
    TipoEvento.find_or_create_by(codigo: 1 ,nome: 'Periodico Alarmado')
    TipoEvento.find_or_create_by(codigo: 3 ,nome: 'Configuração')
    TipoEvento.find_or_create_by(codigo: 4 ,nome: 'Inicialização')
    TipoEvento.find_or_create_by(codigo: 5 ,nome: 'Leitura Instantânea')
    TipoEvento.find_or_create_by(codigo: 8 ,nome: 'Normalização')
    TipoEvento.find_or_create_by(codigo: 9 ,nome: 'Alarme')
  end
end
