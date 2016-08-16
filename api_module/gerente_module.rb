require 'rubygems'
require 'eventmachine'

class GerenteModule < EventMachine::Connection
  def initialize(*args)
    super
    $gerente = self
    manager_connection
  end

  def manager_connection
    EventMachine::PeriodicTimer.new(60) do
      send_id
    end
  end

  def post_init
   send_id
  end

  def receive_data(data)
    logger.info data
  end

  def unbind
    #@timer.cancel
    logger.info 'Gerente desconectado!'
  end


  # Internal : Verifica se existe alguma linha na tabela de saída que deve ser
  #            enviada para a telemetria, se existir envia o pedida de
  #            processamento mais antigo que estiver na tabela de saída
  #            (que ainda não foi  cancelado pelo usuário ou já foi processado)
  #            para que  o gerente realize o processamento.
  #
  # saida - primeira linha da tabela de saída que deve ser envaida para a
  #         telemetria
  #
  def self.checar_saida
    saida = Saida.where('cancelado = ? and data_processamento is ? and modelo_id = ? and aguardando = ?', false, nil, 1, false).first
    GerenteModule.processar_comandos(saida) if saida
  end

  # Internal : recebe um pedido de processamento de comando verifica se o mesmo
  #            ainda não atingiu o limite de tentativas de processamento, se não
  #            verifica qual é o comando a ser processado e envia para a classe
  #            AnalogicProcess::receive_data para que o mesmo envie para a
  #            telemetria
  # saida - Objeto proveniente da tabela saida_analogica
  # telemetria - Objeto proveniente da tabela telemetrias
  # codigo_telemetria - código da telemetria no formato "xxxx"
  #
  def self.processar_comandos(saida)
    if saida.tentativas.to_i  <= LIMITE_TENTIVAS
      saida.update(tentativas: saida.tentativas.to_i + 1)
      telemetria = Telemetria.find(saida.telemetria_id)
      codigo_telemetria = telemetria.codigo.to_s.rjust(4,'0')

      case saida.comando.to_i
      when RESET_TELEMETRY
        logger.info "Tentativa de envio de RESET para telemetria código: #{codigo_telemetria}"
        $gerente.send_data reset_telemetry codigo_telemetria
      when INSTANT_READING
        logger.info "Tentativa de envio de LEITURA INSTANTANEA para a telemetria código: #{codigo_telemetria}"
        $gerente.send_data instant_reading codigo_telemetria

      when CHANGE_PRIMARY_IP
        logger.info "Tentativa de envio de uma MUDANÇA DE IP PRIMÁRIO para a telemetria código: #{codigo_telemetria}"
        $gerente.send_data change_primary_ip codigo_telemetria, '0000', saida

      when CHANGE_SECUNDARY_IP
        logger.info "Tentativa de envio de uma MUDANÇA DE IP SECUNDÁRIO para a telemetria código: #{codigo_telemetria}"
        $gerente.send_data change_secundary_ip codigo_telemetria, '0000', saida

      when CHANGE_HOST_PORT
        logger.info "Tentativa de envio de uma MUDANÇA DE PORTA E HOST para a telemetria código: #{codigo_telemetria}"
        $gerente.send_data change_host codigo_telemetria, '0000', saida
        $gerente.send_data change_port codigo_telemetria, '0000', saida

      # when 04
      #   id_telemetria = saida.codigo_equipamento.to_s.rjust(4,'0')
      #   logger.info id_telemetria
      #
      #   if $gerente.send_data "<0000#{id_telemetria}02FFFF>"
      #   end
      end
    else
      saida.update(cancelado: true)
    end
  end

  def self.change_primary_ip codigo_telemetria, codigo_gerente = '0000', saida
    code = "<#{codigo_gerente}#{codigo_telemetria}0230#{DecToHex.new({ip: saida.ip, port: saida.porta}).ip_port_to_hex}>"
  end

  def self.change_secundary_ip codigo_telemetria, codigo_gerente = '0000', saida
    code = "<#{codigo_gerente}#{codigo_telemetria}0235#{DecToHex.new({ip: saida.ip, port: saida.porta}).ip_port_to_hex}>"
  end

  def self.change_host codigo_telemetria, codigo_gerente = '0000', saida
    code = "<#{codigo_gerente}#{codigo_telemetria}023D#{DecToHex.new({ip: saida.ip, port: saida.porta}).ip_port_to_hex}>"
  end

  def self.change_port codigo_telemetria, codigo_gerente = '0000', saida
    code = "<#{codigo_gerente}#{codigo_telemetria}023E#{DecToHex.new({ip: saida.ip, port: saida.porta}).ip_port_to_hex}>"
  end

  # Internal : Gera o pacote inicial para resetar uma telemetria que será enviando
  #            para AnalogicProcess::receive_data
  #
  # code - pacote de reset da telemetria montado
  #
  def self.reset_telemetry codigo_telemetria, codigo_gerente = '0000'
    code = "<#{codigo_gerente}#{codigo_telemetria}02FFFE>"
  end

  # Internal : Gera o pacote inicial para leitura instantanea de uma telemetria
  #            em AnalogicProcess::receive_data
  #
  # code - pacote de leitura instantânea da telemetria montado
  #
  def self.instant_reading codigo_telemetria, codigo_gerente = '0000'
    code = "<#{codigo_gerente}#{codigo_telemetria}02FFFF>"
  end

  # Internal - Gera o pacote final que sera enviado para a telemetria já com o
  #            o check_sum (validador) do pacote criado.
  #
  # pacote - pacote puro, após a remoção do código da telemetria e do código do
  #          gerente
  #
  def self.obter_pacote(pacote)
    pacote = Pacotes.formatador(pacote)
    pacote = pacote[8..pacote.size]
    pacote = "<#{gerar_check_sum(pacote)}>"
    logger.info "Pacote gerado #{pacote}"
    pacote
  end

  # Internal : Gera o código especial para identificar o gerente que é um código
  #            que não pode pertencer a nenhuma telemetria convencional.
  #
  def send_id
    send_data '<0000>'
  end
end
