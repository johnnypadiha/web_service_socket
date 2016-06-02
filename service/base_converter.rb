# encoding: utf-8

require_relative '../config/constantes.rb'
module BaseConverter
  # Internal : Método responsavel por fazer a conversão do valor vindo em
  # ... hexadecimal para decimal, efetuar calculo base para obtensão do valor ...
  # ... real e a arrendondamento do valor caso seja fracionado.
  #
  # params_hex - Objeto contendo a faixa em hexadecimal para tratamento
  # value_dec - Inteiro contendo a faixa após conversão
  # value_float - Float contendo a faixa após calculo base
  # value - Inteiro contendo a faixa em decimal
  # return - Retorna valor da faixa arrendonda e em decimal
  def self.convert_value_dec(params_hex, min_faixa = 0, min_resto = 0, increment = 1)
    unless params_hex.blank?
      value_dec = params_hex.to_i(BASE_HEXA)
      value_float = (value_dec.to_f * 100 / 255)
      value = value_float.to_i

      if value > min_faixa and (value_float % value) > min_resto
        value += increment
      end
      return value
    end
  end
end
