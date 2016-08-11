# encoding: utf-8

require './api_module/check_sum.rb'
require './api_module/gerente_module.rb'
include CheckSum
require_relative '../service/base_converter'
module AnalogicProcess
  $lista_telemetria = []
  $sockets_conectados = []
  def initialize
    $sockets_conectados << {socket: self, hora: Time.now}
    logger_socket.info "INITIALIZE ---> #{self}"
  end

  def post_init
    logger.info "-- Telemetria Conectada!"
    logger.info "\t--Registrando Telemetria--\n"
    porta, ip = Socket.unpack_sockaddr_in(get_peername)
    logger.info "IP #{ip} Conectado!"
    logger_socket.info "POST_INIT ---> #{self}"
  end

  def receive_data data
    Thread.new do
      data.chomp!
      porta, ip =  Socket.unpack_sockaddr_in(get_peername)

      logger_socket.info "RECEIVE_DATA ---> #{self}"
      # valida se o pacote esta vindo em um formato válido Ex: <xxx>
      if Pacotes.pacote_is_valido data
        id = data[1..4]
        if id.to_i == 0
          cadastrar_telemetria(self, id)

          logger.info "Gerente comunicando..."

          pacote_formatado = Pacotes.formatador data
          id_telemetria = ProcessarPacotes.obtem_codigo_telemetria(pacote_formatado, 4, 7)
          telemetria =
            if id_telemetria.nil?
              id_telemetria
            else
              id_telemetria
              $lista_telemetria.find { |t| t[:id] == id_telemetria }
            end

          if telemetria.nil?
            if pacote_formatado.size == 4
              logger.info "Gerente enviou o ID".blue
            else
              logger.info "A Telemetria de ID #{id_telemetria} não comunicou com o sistema ou não é uma Telemetria válida".red
            end
          else
            logger.info "Telemetria encontrada #{telemetria}"
            logger.info "Enviando pacote para telemetria código: #{telemetria[:id]}"
            telemetria[:socket].send_data GerenteModule.obter_pacote(data)
          end
        else
          logger.info "Pacote recebido #{data}".green
          data = Pacotes::formatador data

          telemetria_existe, codigo = TelemetriaController::verifica_telemetria data
          if !telemetria_existe
            logger.fatal "A Telemetria código: #{codigo} não está cadastrada no sistema e o pacote da mesma foi rejeitado!".red
            close_socket
            return false
          end

          cadastrar_telemetria(self, id)
          self.send_data Hora.gerar_atualizacao_hora
          Pacotes.processador data
        end
      else
        logger.info "pacote: #{data}, possui um formato inválido!".yellow
      end
        logger.info "Telemetrias conectadas #{$lista_telemetria.size}".green
    end
  end

  def unbind
    logger_socket.info "Telemetria desconectada"
  end

  def cadastrar_telemetria(socket, id)
    hora = Time.now
    porta, ip = Socket.unpack_sockaddr_in(get_peername)
    index = $lista_telemetria.find_index { |t| t[:id] == id }
    if index.nil?
      $lista_telemetria << {porta: porta, ip: ip, id: id, hora: hora, socket: self}
    else
      $lista_telemetria[index][:porta] = porta
      $lista_telemetria[index][:ip] = ip
      $lista_telemetria[index][:id] = id
      $lista_telemetria[index][:hora] = hora
      if $lista_telemetria[index][:socket] != self
        close_socket_old $lista_telemetria[index][:socket], id
      end
      $lista_telemetria[index][:socket] = self
    end
  end

  # Internal : Fecha socket que normalmente foi criado para telemetrias que não ...
  # ... possuem cadastro no sistema.
  #
  # self - Socket
  # $sockets_conectados - Lista de sockets que estão conectados no momento.
  def close_socket
    self.close_connection
    $sockets_conectados.delete_if {|s| s[:socket] == self }
  end

  # Internal : Remove socket antigo da telemetria para evitar socket fantasma.
  #
  # socket - Socket da conexão anterior no qual será fechado.
  # codigo_telemetria - Inteiro contendo o código da telemetria conectada
  def close_socket_old socket, codigo_telemetria
    logger_socket.info "Existe um socket antigo da telemetria #{codigo_telemetria} e o mesmo será fechado"
    socket.close_connection
    $sockets_conectados.delete_if {|s| s[:socket] == socket }
  end
end
