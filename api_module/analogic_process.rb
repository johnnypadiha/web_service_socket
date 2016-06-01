require './api_module/check_sum.rb'
require './api_module/gerente_module.rb'
include CheckSum
require_relative '../service/base_converter'
module AnalogicProcess
  $lista_telemetria = []
  def post_init
    logger.info "-- Telemetria Conectada!"
    logger.info "\t--Registrando Telemetria--\n"
    porta, ip = Socket.unpack_sockaddr_in(get_peername)
    logger.info "IP #{ip} Conectado!"
  end

  def receive_data data
    data.chomp!
    porta, ip =  Socket.unpack_sockaddr_in(get_peername)
    id = data[1..4]
    hora = Time.now
    if id.to_i == 0000
      logger.info "Gerente comunicando..."

      id_telemetria = data[5..8]
      telemetria = $lista_telemetria.find { |t| t[:id] == id_telemetria }

      if telemetria.nil?
        if id_telemetria == 'xxxx'
          Saida.create(deleted: false, cancelado: false, codigo_equipamento: 28, tentativa: 0, tipo_comando: 4)
          send_data "teste de leitura instantanea requisitada para o id 28"
        else
          logger.info "A Telemetria de ID #{id_telemetria} não comunicou com o sistema"
        end
      else
        logger.info "Telemetria encontrada #{telemetria}"
        logger.info "Enviando pacote para telemetria"
        telemetria[:socket].send_data GerenteModule.obter_pacote(data)
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
      Raw.create(pacote: data)
      # atualização de hora
      self.send_data Hora.gerar_atualizacao_hora

    # valida se o pacote esta vindo em um formato válido Ex: <xxx>
    # if (data[0] == "<" && data[data.length-3] == ">")
      Pacotes::processador(data) unless data.nil?
    # else
      # logger.info "pacote: #{data}, possui um formato inválido!"
    # end
      logger.info "Pacote recebido #{data}"
      logger.info "Telemetrias conectadas #{$lista_telemetria.size}"
    end
    close_connection if data =~ /quit/i
  end

  def unbind
    puts "-- someone disconnected from the echo server!"
  end
end
