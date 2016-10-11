# encoding: utf-8

require './api_module/check_sum.rb'
require './api_module/gerente_module.rb'
include CheckSum
require_relative '../service/base_converter'
module AnalogicProcess
  $lista_telemetria = []
  $sockets_conectados = []

  # Internal : Inicia conexão de um novo Socket
  #
  # $sockets_conectados - Hash contendo os Sockets conectados ao WebService
  # self - Socket que está sendo iniciado
  def initialize
    $sockets_conectados << {socket: self, hora: Time.now}
    logger_socket.info "INITIALIZE ---> #{self}"
  end

  # Internal : Detecta entrada (conexão) de um novo Socket no WebService
  #
  # porta - Integer contendo a porta na qual a Telemetria está enviando dados.
  # ip - IP na qual a Telemetria está comunicando
  # self - Socket da Telemetria
  def post_init
    logger.info "-- Telemetria Conectada!"
    logger.info "\t--Registrando Telemetria--\n"
    porta, ip = Socket.unpack_sockaddr_in(get_peername)
    logger.info "IP #{ip} Conectado!"
    logger_socket.info "POST_INIT ---> #{self}"
  end

  # Internal : Método interno usado pelo EventMachine, responsável por receber
  #             dados do Socket.
  #            Esse Socket pode ser uma Telemetria ou o Gerente do WebService.
  #            Caso seja uma Telemetria e essa esteja cadastrada na Base de
  #             Dados, o WebService irá cadastrá-la na lista de Telemetrias,
  #             enviar um pacote de Atualização de Hora para a mesma e enviar o
  #             pacote dela para processamento.
  #            Caso a Telemetria não esteja cadastrada, o Socket é fechado e essa
  #             é removida da lista de Sockets.
  #
  # data - Pacote recebido da Telemetria para processamento
  # status_command - resultado da execução do método do Event Machine "send_data"
  #                  se a tentativa de envio for para um socket já desconectado
  #                  o reultado será um número negativo, geralmente "-1"
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
              $lista_telemetria.find { |t| t[:id] == id_telemetria }
            end

          if telemetria.nil?
            if pacote_formatado.size == 4
              logger.info "Gerente enviou o ID".blue
            else
              logger.info "A Telemetria de ID #{id_telemetria} não comunicou com o sistema ou não é uma Telemetria válida".red
            end
          else

            package = GerenteModule.obter_pacote(data)
            if package
              status_command = telemetria[:socket].send_data package
              if status_command > 0
                logger.info "Enviando pacote: #{pacote} para telemetria código: #{telemetria[:id]}"
              else
                logger.info "Falha ao enviar pacote: #{pacote} para telemetria código: #{telemetria[:id]}, provavelmente socket OFF ou zumbi".red
              end
            else
              logger.info "A telemetria : #{telemetria[:id]}, Não respondeu e foi desconectada".red
              telemetria[:socket].close_socket
            end

          end
        else
          logger.info "Pacote recebido #{data}".green
          data = Pacotes::formatador data
          telemetria_existe, codigo = TelemetriaController::verifica_telemetria data, ip
          if !telemetria_existe
            logger.fatal "A Telemetria código: #{codigo} não está cadastrada no sistema e o pacote da mesma foi rejeitado!".red
            close_socket
            return false
          end

          cadastrar_telemetria(self, id)

          Pacotes.processador data, self
        end
      else
        logger.info "pacote: #{data}, possui um formato inválido!".yellow
      end
        logger_comunicacao.info "Telemetrias conectadas #{$lista_telemetria.select { |t| t[:id].to_i != 0}.size}".green
    end
  end

  # Internal : Function interna do EventMachine responsável por finalizar um
  #             socket.
  #
  # return - Mensagem informando que a Telemetria foi desconectada.
  def unbind
    logger_socket.info "Telemetria desconectada"
  end

  # Internal : Insere os dados de uma Telemetria na lista de Telemetrias conectadas
  #             cada vez que essa se cria um novo Socket no WebService e envia o
  #             primeiro pacote válido.
  #            A action também valida se aquela Telemetria já manteve comunicação
  #             anteriormente e possuia um registro antigo na lista. Caso tenha
  #             mantido, o Socket antigo é fechado e o registro (também antigo)
  #             é removido da lista.
  #
  # socket - Socket da conexão
  # id - Integer contendo o id da Telemetria em comunicação
  # $lista_telemetria - Hash contendo uma lista de Telemetrias válidas em
  #             comunicação com o WebService.
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

  # Internal : Fecha socket que normalmente foi criado para telemetrias que não
  #             possuem cadastro no sistema.
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
