module BaseConverter

  # Public : Recebe um decimal como parâmetro e converte para hexadecimal
  #
  # params_dec - Parâmetro contendo o decimal
  # Retorna valor convertido em hexadecimal
  def self.convert_to_hex(params_dec)
    unless params_dec.blank?
      data = params_dec.to_i
      response = data.to_s(16)

      return response.upcase
    end
  end

  # Public : Recebe um hexadecimal como parâmetro e converte para decimal
  #
  # params_hex - Parâmetro contendo o hexadecimal
  # Retorna valor convertido em decimal
  def self.convert_to_dec(params_hex)
    unless params_hex.blank?
      response = params_hex.to_i(16)

      return response
    end
  end
end
