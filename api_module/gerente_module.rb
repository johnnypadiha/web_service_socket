require 'rubygems'
require 'eventmachine'
require 'pp'

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

      when CHANGE_HOST
        logger.info "Tentativa de envio de uma MUDANÇA DE HOST para a telemetria código: #{codigo_telemetria}"
        $gerente.send_data change_host codigo_telemetria, '0000', saida

      when CHANGE_PORT
        logger.info "Tentativa de envio de uma MUDANÇA DE PORTA para a telemetria código: #{codigo_telemetria}"
        $gerente.send_data change_port codigo_telemetria, '0000', saida

      when CHANGE_FAIXA_TIMER
        logger.info "Tentativa de envio de MUDANÇA DE FAIXA E TIMER para a telemetria código: #{codigo_telemetria}"
        saida_faixas = SaidaFaixas.find_by_saida_id(saida.id)
        medida = Medida.find(saida.medida_id)
        $gerente.send_data change_faixa_timer codigo_telemetria, '0000', saida, saida_faixas, medida, telemetria

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

  # Internal : Gera o pacote de mudança de faixas e timers
  #
  # maximo - valor em hexadecimal e byte do maximo da faixa verde
  # minimo - valor em hexadecimal e byte do mínimo da faixa verde
  # timer - valor em hexadecimal do timer da medida
  # id_local - valor em hexadecimal do id_local da medida
  #
  # retorna o pacote de mudança de faixa e timer ainda sem o checksum
  def self.change_faixa_timer codigo_telemetria, codigo_gerente = '0000', saida, saida_faixas, medida_params, telemetria

    maximo = BaseConverter.convert_to_byte(saida_faixas.maximo)
    maximo = BaseConverter.convert_to_hexa(maximo)

    minimo = BaseConverter.convert_to_byte(saida_faixas.minimo)
    minimo = BaseConverter.convert_to_hexa(minimo)

    timer = BaseConverter.convert_to_hexa(saida.valor)
    id_local = BaseConverter.convert_to_hexa(medida_params.id_local)

    if medida_params.id_local >= 21
      medidas = []
      novas_faixas = {21 => [0,0], 22 => [0,0], 23 => [0,0], 24 => [0,0]}
      equipamentos = telemetria.equipamentos

      equipamentos.each do |equipamento|
        medidas += Medida.where(equipamento_id: equipamento.id, id_local: [21,22,23,24]).order("id desc").limit(4)
      end

      medidas = medidas.uniq { |medida| medida.id_local}

      medidas.each do |medida|

        if medida.id_local == medida_params.id_local
          novas_faixas[medida.id_local][0] = saida_faixas.minimo.to_i
          novas_faixas[medida.id_local][1] = medida_params.timer.to_i

        else
          valor_digital = medida.faixas.select(:minimo).where(status_faixa: 1)
          novas_faixas[medida.id_local][0] = valor_digital[0].minimo.to_i
          novas_faixas[medida.id_local][1] = medida.timer.to_i
        end
      end

      faixas_digitais_binarias = "#{novas_faixas[21][0]}#{novas_faixas[22][0]}#{novas_faixas[23][0]}#{novas_faixas[24][0]}"

      faixas_digitais_binarias = faixas_digitais_binarias.to_i(2)

      faixas_digitais_binarias = BaseConverter.convert_to_hexa(faixas_digitais_binarias)

      timer_D1 = novas_faixas[21][1]
      timer_D1 = BaseConverter.convert_to_hexa(timer_D1)

      timer_D2 = novas_faixas[22][1]
      timer_D2 = BaseConverter.convert_to_hexa(timer_D2)

      timer_D3 = novas_faixas[23][1]
      timer_D3 = BaseConverter.convert_to_hexa(timer_D3)

      timer_D4 = novas_faixas[24][1]
      timer_D4 = BaseConverter.convert_to_hexa(timer_D4)

      code = "<#{codigo_gerente}#{codigo_telemetria}0215#{faixas_digitais_binarias}#{timer_D1}#{timer_D2}#{timer_D3}#{timer_D4}>".upcase
    else

      code = "<#{codigo_gerente}#{codigo_telemetria}02#{id_local}#{minimo}#{maximo}#{timer}>".upcase
    end
  end

  # Internal : Gera o pacote de mudança de IP primário, que será enviando
  #            para AnalogicProcess::receive_data
  #
  # code - pacote de mudança de "IP primário" da telemetria montado
  #
  def self.change_primary_ip codigo_telemetria, codigo_gerente = '0000', saida
    code = "<#{codigo_gerente}#{codigo_telemetria}0230#{DecToHex.new({ip: saida.ip, port: saida.porta}).ip_port_to_hex}>"
  end

  # Internal : Gera o pacote de mudança de IP secundário, que será enviando
  #            para AnalogicProcess::receive_data
  #
  # code - pacote de mudança de "IP secundário" da telemetria montado
  #
  def self.change_secundary_ip codigo_telemetria, codigo_gerente = '0000', saida
    code = "<#{codigo_gerente}#{codigo_telemetria}0235#{DecToHex.new({ip: saida.ip, port: saida.porta}).ip_port_to_hex}>"
  end

  # Internal : Gera o pacote de mudança de host, que será enviando
  #            para AnalogicProcess::receive_data
  #
  # code - pacote de mudança de "host" da telemetria montado
  #
  def self.change_host codigo_telemetria, codigo_gerente = '0000', saida
    code = "<#{codigo_gerente}#{codigo_telemetria}023D#{DecToHex.new({host: saida.host}).host_to_hex}>"
  end

  # Internal : Gera o pacote de mudança de Porta do host, que será enviando
  #            para AnalogicProcess::receive_data
  #
  # code - pacote de mudança de "Porta do host"" da telemetria montado
  #
  def self.change_port codigo_telemetria, codigo_gerente = '0000', saida
    code = "<#{codigo_gerente}#{codigo_telemetria}023E#{DecToHex.new({port: saida.porta}).port_to_hex}>"
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
