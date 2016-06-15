# encoding: utf-8

require './api_module/check_sum.rb'
require './api_module/gerente_module.rb'
include CheckSum
require_relative '../service/base_converter'
module AnalogicProcess
  $lista_telemetria = []
  def initialize
    logger_socket.info "#{self}"
  end

  def post_init
    logger.info "-- Telemetria Conectada!"
    logger.info "\t--Registrando Telemetria--\n"
    porta, ip = Socket.unpack_sockaddr_in(get_peername)
    logger.info "IP #{ip} Conectado!"
  end

  def receive_data data
    data.chomp!
    porta, ip =  Socket.unpack_sockaddr_in(get_peername)

      # valida se o pacote esta vindo em um formato válido Ex: <xxx>
    if Pacotes.pacote_is_valido data
      id = data[1..4]
      hora = Time.now
      if id.to_i == 0
        logger.info "Gerente comunicando..."

        pacote_formatado = Pacotes.formatador data
        id_telemetria = ProcessarPacotes.obtem_codigo_telemetria(pacote_formatado, 4, 7)
        telemetria =
          if id_telemetria.nil?
            id_telemetria
          else
            $lista_telemetria.find { |t| t[:id] == id_telemetria }
          end

        if telemetria.nil?
          if id_telemetria == 'xxxx'
            Saida.create(deleted: false, cancelado: false, codigo_equipamento: 9999, tentativa: 0, tipo_comando: 4)
            send_data "teste de leitura instantanea requisitada para o id 28".blue
          else
            if pacote_formatado.size == 4
              logger.info "Gerente enviou o ID".blue
            else
              logger.info "A Telemetria de ID #{id_telemetria} não comunicou com o sistema ou não é uma Telemetria vádia".red
            end
          end
        else
          logger.info "Telemetria encontrada #{telemetria}"
          logger.info "Enviando pacote para telemetria"
          telemetria[:socket].send_data GerenteModule.obter_pacote(data)
        end
      else
        logger.info "Pacote recebido #{data}".green
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
        Pacotes.processador data
      end
    else
      logger.info "pacote: #{data}, possui um formato inválido!".yellow
    end
      logger.info "Telemetrias conectadas #{$lista_telemetria.size}".green
  end

  def unbind
    logger_socket.info "Telemetria desconectada"
    #self.close_connection
    puts "-- someone disconnected from the echo server!"
  end
end
