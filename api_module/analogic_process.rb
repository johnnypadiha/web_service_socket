require './api_module/check_sum.rb'

include CheckSum
module AnalogicProcess
  $lista_telemetria = []
  def post_init
    logger.info "-- Telemetria Conectada!"
    logger.info "\t--Registrando Telemetria--\n"
    porta, ip = Socket.unpack_sockaddr_in(get_peername)
    logger.info "IP #{ip} Conectado!"
  end

  def receive_data data
    porta, ip =  Socket.unpack_sockaddr_in(get_peername)
    id = data[1..4]
    hora = Time.now
    if id.to_i == 0000
      logger.info "Gerente comunicando..."

      id_telemetria = data[5..8]
      telemetria = $lista_telemetria.find { |t| t[:id] == id_telemetria }

      if telemetria.nil?
        logger.info "A Telemetria de ID #{id_telemetria} não comunicou com o sistema"
      else
        logger.info "Telemetria encontrada #{telemetria}"
        logger.info "Enviando pacote para telemetria"
        telemetria[:socket].send_data "<02FFFE03>"
      end
    else
      index = $lista_telemetria.find_index { |t| t[:id] == id }
      if index.nil?
        $lista_telemetria << {porta: porta, ip: ip, id: id, hora: hora, socket: self}
      else
        $lista_telemetria[index][:porta] = porta
        $lista_telemetria[index][:ip] = ip
        $lista_telemetria[index][:id] = id
        $lista_telemetria[index][:hora] = hora
        $lista_telemetria[index][:socket] = self
      end
    end
    # atualização de hora
    self.send_data Hora.gerar_atualizacao_hora

    # valida se o pacote esta vindo em um formato válido Ex: <xxx>
    if (data[0] == "<" && data[data.length-3] == ">")
      Pacotes::processador(data)
    else
      logger.info "pacote: #{data}, possui um formato inválido!"
    end

    logger.info "Pacote recebido #{data}"
    logger.info "Telemetrias conectadas #{$lista_telemetria.size}"
    close_connection if data =~ /quit/i
  end

  def unbind
    puts "-- someone disconnected from the echo server!"
  end
end
