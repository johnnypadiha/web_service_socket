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
    self.send_data gerar_atualizacao_hora

    logger.info "Pacote recebido #{data}"
    logger.info "Telemetrias conectadas #{$lista_telemetria.size}"
    close_connection if data =~ /quit/i
  end

  def unbind
    puts "-- someone disconnected from the echo server!"
  end

  def gerar_atualizacao_hora
    response = '<00'
    data = Time.now.strftime("%y%m%d%H%M%S")
    checkError = 0

    for i in 0..5
      temp = data[2 * i ... (2 * i) + 2].to_i
      response += temp.to_s(16).rjust(2, '0').upcase

      checkError ^= temp
    end

      response += checkError.to_s(16).rjust(2,'0').upcase
      response += '>'

      logger.info "Pacote de atualização de Hora ---> #{response}"

      response
  end

  def gerar_check_sum
    i = 0
    cs = 0
    while i < comando.size
        if i % 2 == 1
          byte_pacote = comando[i - 1 .. i]
          cs ^= byte_pacote.hex.to_s(10).to_i
        end
      i += 1
    end
    cs.to_s(16).rjust(2,'0').upcase

    comando += cs.to_s(16).rjust(2,'0').upcase

    comando
  end
end
