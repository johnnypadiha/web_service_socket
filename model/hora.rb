require_relative '../config/constantes.rb'
class Hora
  def self.gerar_atualizacao_hora
    response = ''
    data = Time.now.strftime("%y%m%d%H%M%S")

    for i in 0..5
      temp = data[2 * i ... (2 * i) + 2].to_i
      response += temp.to_s(BASE_HEXA).rjust(2, '0').upcase
    end
    logger.info "Pacote de atualização de Hora ---> #{response}"

    "<00#{gerar_check_sum(response)}>"
  end
end
