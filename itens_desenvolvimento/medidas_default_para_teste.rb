require 'active_record'
require_relative '../model/medida.rb'
class MedidasDeafult
  def initialize
    ActiveRecord::Base.configurations = YAML.load(IO.read("../db/config.yml"))
    ActiveRecord::Base.establish_connection(:production)
    #ActiveRecord::Base.establish_connection(:development)
    ActiveRecord::Base.default_timezone = :local

    gerar_medidas
  end

  def gerar_medidas

    Medida.find_or_create_by(codigo_medida:'DBM', nome_medida: 'Nivel Sinal', equipamento_id: 1)

    Medida.find_or_create_by(codigo_medida:'A1', nome_medida:'A1', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A2', nome_medida:'A2', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A3', nome_medida:'A3', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A4', nome_medida:'A4', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A5', nome_medida:'A5', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A6', nome_medida:'A6', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A7', nome_medida:'A7', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A8', nome_medida:'A8', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A9', nome_medida:'A9', equipamento_id:1)

    Medida.find_or_create_by(codigo_medida:'A10', nome_medida:'A10', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A11', nome_medida:'A11', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A12', nome_medida:'A12', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A13', nome_medida:'A13', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A14', nome_medida:'A14', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A15', nome_medida:'A15', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'A16', nome_medida:'A16', equipamento_id:1)

    Medida.find_or_create_by(codigo_medida:'N1', nome_medida:'N1', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'N2', nome_medida:'N2', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'N3', nome_medida:'N3', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'N4', nome_medida:'N4', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'D1', nome_medida:'D1', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'D2', nome_medida:'D2', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'D3', nome_medida:'D3', equipamento_id:1)
    Medida.find_or_create_by(codigo_medida:'D4', nome_medida:'D4', equipamento_id:1)
  end
end

MedidasDeafult.new
