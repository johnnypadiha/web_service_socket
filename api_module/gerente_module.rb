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
    saida = Saida.check_out false, nil, 1, false
    if saida
      package = GerenteModule.processar_comandos(saida)
      $gerente.send_data package
    end
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
    telemetria = Telemetria.find(saida.telemetria_id)
    codigo_telemetria = telemetria.codigo.to_s.rjust(4,'0')
    saida.update(tentativas: saida.tentativas.to_i + 1)

    if saida.tentativas.to_i <= LIMITE_TENTATIVAS_INDIVIDUAL
      case saida.comando.to_i
      when RESET_TELEMETRY
        logger.info "Tentativa de envio de RESET para telemetria código: #{codigo_telemetria}"
        reset_telemetry codigo_telemetria
      when INSTANT_READING
        logger.info "Tentativa de envio de LEITURA INSTANTANEA para a telemetria código: #{codigo_telemetria}"
        instant_reading codigo_telemetria

      when CHANGE_PRIMARY_IP
        logger.info "Tentativa de envio de uma MUDANÇA DE IP PRIMÁRIO para a telemetria código: #{codigo_telemetria}"
        change_primary_ip codigo_telemetria, '0000', saida

      when CHANGE_SECUNDARY_IP
        logger.info "Tentativa de envio de uma MUDANÇA DE IP SECUNDÁRIO para a telemetria código: #{codigo_telemetria}"
        change_secundary_ip codigo_telemetria, '0000', saida

      when CHANGE_HOST
        logger.info "Tentativa de envio de uma MUDANÇA DE HOST para a telemetria código: #{codigo_telemetria}"
        change_host codigo_telemetria, '0000', saida

      when CHANGE_PORT
        logger.info "Tentativa de envio de uma MUDANÇA DE PORTA para a telemetria código: #{codigo_telemetria}"
        change_port codigo_telemetria, '0000', saida

      when CHANGE_FAIXA_TIMER
        logger.info "Tentativa de envio de MUDANÇA DE FAIXA E TIMER para a telemetria código: #{codigo_telemetria}"
        saida_faixas = SaidaFaixas.find_by_saida_id(saida.id)
        medida = Medida.find(saida.medida_id)
        change_faixa_timer codigo_telemetria, '0000', saida, saida_faixas, medida, telemetria

      end
    else
      saida.update(cancelado: true)
      disconnect_telemetry codigo_telemetria, '0000'
    end
  end

  def self.disconnect_telemetry(telemetry_code, gerent_code)
    "<#{gerent_code}#{telemetry_code}1>"
  end

  # Internal : Gera o pacote de mudança de faixas e timers
  #
  # maximo - valor em hexadecimal e byte do maximo da faixa verde
  # minimo - valor em hexadecimal e byte do mínimo da faixa verde
  # timer - valor em hexadecimal do timer da medida
  # id_local - valor em hexadecimal do id_local da medida
  # equipamentos - Array contendo os IDs dos equipamentos que pertencem a telemetria
  # em questão
  # medidas - Lista de objetos de medida, contendo a última configuração de medida
  #           de uma medida digital
  #
  # retorna o pacote de mudança de faixa e timer ainda sem o checksum, caso a medida_params
  # que solicitou a mudança seja digital, gera um pacote diferenciado, devido ao fato da
  # telemetria só receber a modificação de medida digital quando vier as 4 juntas
  def self.change_faixa_timer codigo_telemetria, codigo_gerente = '0000', saida, saida_faixas, medida_params, telemetria
    if medida_params.id_local >= INICIO_DIGITAIS
      equipamentos = telemetria.equipamentos.pluck(:id)

      medidas = Medida.last_environment_measures equipamentos
      new_tracks = digital_tracks_generate medidas, medida_params, saida_faixas, saida

      faixas_digitais_hexa = digital_tracks new_tracks
      timer_D1, timer_D2, timer_D3, timer_D4 = digital_tracks_timers new_tracks

      code = "<#{codigo_gerente}#{codigo_telemetria}0215#{faixas_digitais_hexa}#{timer_D1}#{timer_D2}#{timer_D3}#{timer_D4}>".upcase
    else
      maximo, minimo, timer, id_local = analogico_tracks_generate saida_faixas, saida, medida_params

      code = "<#{codigo_gerente}#{codigo_telemetria}02#{id_local}#{minimo}#{maximo}#{timer}>".upcase
    end
  end

  # Internal - Gera novos valores para faixas e timer da medida analógicas, que
  #            foi solicitada a mudança
  # Retorna os valores máximo, mínimo, timer e id_local sendo os três primeiros
  # em hexadecimal
  def self.analogico_tracks_generate saida_faixas, saida, medida_params
    minimo, maximo = orange_track_to_green saida_faixas
    maximo = BaseConverter.convert_to_byte(maximo.to_i)
    maximo = BaseConverter.convert_to_hexa(maximo)

    minimo = BaseConverter.convert_to_byte(minimo.to_i)
    minimo = BaseConverter.convert_to_hexa(minimo)

    timer = BaseConverter.convert_to_hexa(saida.valor)
    id_local = BaseConverter.convert_to_hexa(medida_params.id_local)

    return maximo, minimo, timer, id_local
  end

  # Internal - Unifica a faixa laranja com a faixa verde da telemetria analógica
  #            para que ao enviar uma faixa para telemetria a ela considere que
  #            a faixa laranja e a verde seja a mesma coisa, ou seja "verde"
  #
  # Retorna o inicio e o fim da faixa verde que será enviada para a telemetria
  def self.orange_track_to_green saida_faixas
      if saida_faixas.maximo < saida_faixas.minimo_laranja
        minimo = saida_faixas.minimo
        maximo = saida_faixas.maximo_laranja
      else
        minimo = saida_faixas.minimo_laranja
        maximo = saida_faixas.maximo
      end
    return minimo, maximo
  end

  # Internal - Gera novos valores para faixas e timers das medidas digitais, se
  #            alguma medida digital não foi informada pelo usuário pega o valor
  #            da última configuração recebida da mesma.
  #
  # new_tracks : Hash contendo os valor atual das medidas digitais e o timer
  #
  # Retorna um Hash com a faixa e o timer das medidas digitais
  def self.digital_tracks_generate medidas, medida_params, saida_faixas, saida
    new_tracks = {D1 => [0,0], D2 => [0,0], D3 => [0,0], D4 => [0,0]}
    medidas.each do |medida|

      if medida.id_local == medida_params.id_local
        new_tracks[medida.id_local][0] = saida_faixas.minimo.to_i
        new_tracks[medida.id_local][1] = saida.valor.to_i
      else
        valor_digital = medida.faixas.select(:minimo).where(status_faixa: 1)
        new_tracks[medida.id_local][0] = valor_digital[0].minimo.to_i
        new_tracks[medida.id_local][1] = medida.timer.to_i
      end
    end
    return new_tracks
  end

  # Internal - separa os timers das medidas digitais e converte para hexadecimal
  #
  # Retorna os timers das medidas digitais em hexadecimal
  def self.digital_tracks_timers new_tracks
    timer_D1 = new_tracks[D1][1]
    timer_D1 = BaseConverter.convert_to_hexa(timer_D1)
    timer_D2 = new_tracks[D2][1]
    timer_D2 = BaseConverter.convert_to_hexa(timer_D2)
    timer_D3 = new_tracks[D3][1]
    timer_D3 = BaseConverter.convert_to_hexa(timer_D3)
    timer_D4 = new_tracks[D4][1]
    timer_D4 = BaseConverter.convert_to_hexa(timer_D4)
    return timer_D1, timer_D2, timer_D3, timer_D4
  end

  # Internal - Recebe os valores das faixas digitais em Decimal, converte para
  #            binário, inverte a posição e converte para hexadecimal
  #
  # Retorna os timers das medidas Digitais em hexadecimal
  def self.digital_tracks new_tracks
    faixas_digitais_binarias = "#{new_tracks[D4][0]}#{new_tracks[D3][0]}#{new_tracks[D2][0]}#{new_tracks[D1][0]}"
    faixas_digitais_binarias = faixas_digitais_binarias.reverse
    faixas_digitais_binarias = faixas_digitais_binarias.to_i(BASE_BIN)
    faixas_digitais_hexa = BaseConverter.convert_to_hexa(faixas_digitais_binarias)
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
    if pacote.to_i == 1
      false
    else
      logger.info "Pacote gerado #{pacote}"
      pacote = "<#{gerar_check_sum(pacote)}>"
    end
  end

  # Internal : Gera o código especial para identificar o gerente que é um código
  #            que não pode pertencer a nenhuma telemetria convencional.
  #
  def send_id
    send_data '<0000>'
  end
end
