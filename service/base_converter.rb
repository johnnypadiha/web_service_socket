# encoding: utf-8
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

  # Internal : Converte para hexadecimal mantendo 2 casas decimais, mesmo quando
  #            não o hexa não atender esse tamanho
  #
  # value - Valor a ser convertido para hexadecimal
  #
  # Retorna um hexadecimal de 2 casas
  def self.convert_to_hexa value
    value.to_i.to_s(16).rjust(2,'0')
  end

  # Internal : Converte para byte, limite 255
  #
  # value - Valor em byte
  #
  # Retorna um valor em byte 
  def self.convert_to_byte value
    value = ((value.to_f * 255) / 100).to_i
  end
end
