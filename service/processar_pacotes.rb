# encoding: utf-8
require_relative '../service/processar_pacotes.rb'
require_relative '../controller/telemetria_controller.rb'

class ProcessarPacotes
  # Internal: Extrai as medidas do pacote .
  #
  # pacote - Hash contendo as medidas conforme enviadas pela telemetria.
  # medidas - Hash contendo as medidas pronta para serem persisitidas.
  #
  # Retorna as medidas separadas
  def self.leituras_instantanea pacote
    medidas = Hash.new
    medidas[:codigo_telemetria] = ProcessarPacotes::obtem_codigo_telemetria pacote
    medidas[:tipo_pacote] = (ProcessarPacotes::obtem_tipo_pacote pacote).to_i
    medidas[:DBM] =
      if pacote.size == 72
        ProcessarPacotes::obtem_nivel_sinal(pacote, 58, 62)
      else
        ProcessarPacotes::obtem_nivel_sinal pacote
      end

    medidas[:leituras] = ProcessarPacotes::obtem_medidas pacote
    medidas
  end

  # Internal: Processa o pacote de inicialização
  #
  # pacote - Hash com as medidas a monitorar
  # inicializacao - Hash contendo as medidas de inicializacao
  #
  # Retorna as medidas devidamente corretas.
  def self.inicializacao pacote
    inicializacao = Hash.new
    inicializacao[:codigo_telemetria] = ProcessarPacotes::obtem_codigo_telemetria pacote
    inicializacao[:data] = Time.now
    inicializacao[:DBM] = ProcessarPacotes::obtem_nivel_sinal pacote
    inicializacao[:leituras] = ProcessarPacotes::obtem_medidas pacote
    return inicializacao
  end

  def self.configuracao pacote
    configuracao_hex, telemetria = ProcessarPacotes::divide_pacote(pacote)
    analogicas, negativas, digitais = ProcessarPacotes.processa_configuracao configuracao_hex
    result, id_telemetria = ProcessarPacotes::find_and_update_telemetria telemetria

    if result
      if Medida::create_medidas id_telemetria, analogicas, negativas, digitais
        logger.info "Configuração da telemetria #{telemetria[:codigo_telemetria]} processada e persistida com sucesso!".blue
      else
        logger.fatal "Problemas ao persistir configuração da telemetria código: #{telemetria[:codigo_telemetria]}".red
      end
    else
      logger.info "Houveram erros ao persistir o pacote de Configuração da telemetria #{telemetria[:codigo_telemetria]}".red
    end
  end

  # Recebe um haxadecimal e converte para String, caso se 0 não tenta converter
  # telemetria[:host] = configuracao_hex[:host].hex == 0 ? 0 : configuracao_hex[:host].split.pack('H*').gsub("\0","")
  def self.divide_pacote(pacote)
    configuracao_hex = Hash.new
    telemetria = Hash.new
    configuracao_hex[:analogicas] = pacote[10..73]
    configuracao_hex[:negativas] = pacote[74..90]
    configuracao_hex[:digitais] = pacote[91..91]
    configuracao_hex[:timers_analogicas] = pacote[92..123]
    configuracao_hex[:timers_negativas] = pacote[124..131]
    configuracao_hex[:timers_digitais] = pacote[132..140]
    configuracao_hex[:timer_periodico] = pacote[148..151]
    configuracao_hex[:operadora] = pacote[152..153]
    configuracao_hex[:ip_primario_1octeto] = pacote[154..155]
    configuracao_hex[:ip_primario_2octeto] = pacote[156..157]
    configuracao_hex[:ip_primario_3octeto] = pacote[158..159]
    configuracao_hex[:ip_primario_4octeto] = pacote[160..161]
    configuracao_hex[:porta_ip_primario] = pacote[162..165]
    configuracao_hex[:ip_secundario_1octeto] = pacote[166..167]
    configuracao_hex[:ip_secundario_2octeto] = pacote[168..169]
    configuracao_hex[:ip_secundario_3octeto] = pacote[170..171]
    configuracao_hex[:ip_secundario_4octeto] = pacote[172..173]
    configuracao_hex[:porta_ip_secundario] = pacote[174..177]
    configuracao_hex[:host] = pacote[178..183]
    configuracao_hex[:porta_dns] = pacote[184..187]
    telemetria[:data] = Time.now
    telemetria[:codigo_telemetria] = ProcessarPacotes::obtem_codigo_telemetria pacote
    telemetria[:firmware] = ProcessarPacotes::obtem_firmware pacote
    telemetria[:ip_primario] = "#{configuracao_hex[:ip_primario_1octeto].hex}.#{configuracao_hex[:ip_primario_2octeto].hex}.#{configuracao_hex[:ip_primario_3octeto].hex}.#{configuracao_hex[:ip_primario_4octeto].hex}"
    telemetria[:ip_secundario] = "#{configuracao_hex[:ip_secundario_1octeto].hex}.#{configuracao_hex[:ip_secundario_2octeto].hex}.#{configuracao_hex[:ip_secundario_3octeto].hex}.#{configuracao_hex[:ip_secundario_4octeto].hex}"
    telemetria[:porta_ip_primario] = configuracao_hex[:porta_ip_primario].hex
    telemetria[:porta_ip_secundario] = configuracao_hex[:porta_ip_secundario].hex
    telemetria[:operadora] = configuracao_hex[:operadora].hex
    telemetria[:host] = configuracao_hex[:host].hex == 0 ? 0 : configuracao_hex[:host].split.pack('H*').gsub("\0","")
    telemetria[:porta_dns] = configuracao_hex[:porta_dns].hex
    telemetria[:timer_periodico] = configuracao_hex[:timer_periodico].hex / BASE_SEGUNDOS

    return configuracao_hex, telemetria
  end


  # Internal - Recebe um Hash com vários Hexadecimais que representam o pacote de
  # configuração já pré dividido, e retorna 4 Hashses, medidas: ANALÓGICAS,
  # NEGATIVAS e DIGITAIS com suas respectivas faixas e timers.
  #
  # digitais_bin : recebe um Hexa que representa as medidas digitais converte
  #                para binario, garante que ele tenha 4 digitos um para cada
  #                digital D1, D2, D3 e D4.
  #
  # Examples
  #
  #   processa_configuracao({:analogicas=>"007A00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF", :negativas=>"00FF00FF00FF00660", :digitais=>"F", :timers_analogicas=>"000F0F0F0F0F0F0F0F0F0F0F0F0F0F0F", :timers_negativas=>"0F0F0F0F", :timers_digitais=>"0F0F0F0FF", :timer_periodico=>"00B4", :operadora=>"02", :ip_primario_1octeto=>"2D", :ip_primario_2octeto=>"37", :ip_primario_3octeto=>"E9", :ip_primario_4octeto=>"89", :porta_ip_primario=>"15CC", :ip_secundario_1octeto=>"2D", :ip_secundario_2octeto=>"37", :ip_secundario_3octeto=>"E9", :ip_secundario_4octeto=>"89", :porta_ip_secundario=>"15CC", :host=>"000000", :porta_dns=>"15CC"})
  #   # => {"A1"=>{:minimo=>0, :maximo=>48, :timer=>"0"}, "A2"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A3"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A4"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A5"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A6"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A7"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A8"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A9"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A10"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A11"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A12"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A13"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A14"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A15"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "A16"=>{:minimo=>0, :maximo=>100, :timer=>"15"}}
  #   # => {"N1"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "N2"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "N3"=>{:minimo=>0, :maximo=>100, :timer=>"15"}, "N4"=>{:minimo=>0, :maximo=>40, :timer=>"15"}}
  #   # => {"D1"=>{:normal=>"1", :timer=>"15"}, "D2"=>{:normal=>"1", :timer=>"15"}, "D3"=>{:normal=>"1", :timer=>"15"}, "D4"=>{:normal=>"1", :timer=>"15"}}
  #
  # Retorna 4 (ANALOGICOS, DIGITAIS e NEGATIVAS) Hash com o mínimo, máximo e timer
  # de cada medida.
  def self.processa_configuracao (configuracao_hex)
    digitais_bin = configuracao_hex[:digitais].hex.to_s(BASE_BIN).rjust(4,'0')[0..3]
    cont = 0
    time_cont = 0
    medidas = Hash.new
    analogicas = Hash.new
    negativas = Hash.new
    digitais = Hash.new
    QTDE_ANALOGICAS.times do |i|
      fundo_escala = Hash.new
      fundo_escala[:minimo] = BaseConverter.convert_value_dec configuracao_hex[:analogicas][cont ... cont+2]
      fundo_escala[:maximo] = BaseConverter.convert_value_dec configuracao_hex[:analogicas][cont+2 ... cont+4]
      fundo_escala[:timer] = configuracao_hex[:timers_analogicas][time_cont ... time_cont+2].hex.to_s(BASE_DEC)
      analogicas["A#{i+1}"] = fundo_escala
      time_cont = time_cont+2
      cont = cont+4
    end
    cont = 0
    time_cont = 0
    QTDE_NEGATIVAS.times do |i|
      fundo_escala = Hash.new
      fundo_escala[:minimo] = BaseConverter.convert_value_dec configuracao_hex[:negativas][cont ... cont+2]
      fundo_escala[:maximo] = BaseConverter.convert_value_dec configuracao_hex[:negativas][cont+2 ... cont+4]
      fundo_escala[:timer] = configuracao_hex[:timers_negativas][time_cont ... time_cont+2].hex.to_s(BASE_DEC)
      negativas["N#{i+1}"] = fundo_escala
      time_cont = time_cont+2
      cont = cont+4
    end
    time_cont = 0
    QTDE_DIGITAIS.times do |i|
      fundo_escala = Hash.new
      fundo_escala[:normal] = digitais_bin[i]
      fundo_escala[:timer] = configuracao_hex[:timers_digitais][time_cont ... time_cont+2].hex.to_s(BASE_DEC)
      digitais["D#{i+1}"] = fundo_escala
      time_cont = time_cont+2
    end
    return analogicas, negativas, digitais
  end

  # Internal - Responsável por verificar na tabela de saída se a resposta de uma
  #            uma telemetria pertence a algum comando que está pendente na mesma
  #
  # codigo_telemetria - String codigo da telemetria proveniente do pacote
  # telemetry - Inteiro ,chave primária da telemetria do qual pertence o pacote
  # pacote - String, pacote proveniente da telemetria contendo todos os dados de resposta
  #          de um comando que foi solicitado anteriormente
  #
  def self.processa_confirmacao_comandos pacote
    logger.info "PACOTE RECEBIDO >>>>>>>>>> #{pacote} <<<<<<<<<<<<<<<<<<<<<<".blue
    codigo_telemetria = ProcessarPacotes.obtem_codigo_telemetria pacote
    telemetry = Telemetria.select(:id).find_by_codigo(codigo_telemetria)
    pacote =  pacote[6..9]

    if pacote[0..1] == "FF"

      case pacote.to_s
      when "FFFF"
        write_command_log "LEITURA_INSTANTANEA", codigo_telemetria
        output_persistence_command telemetry, INSTANT_READING

      when "FFFE"
        write_command_log "RESET", codigo_telemetria
        output_persistence_command telemetry, RESET_TELEMETRY

      else
        logger.info "Telemetria: #{codigo_telemetria} avisa que processou o pacote: #{pacote}, mas... que p* de pacote é esse?".blue
      end

    else

      case pacote[0..1].to_s
      when "30"
        write_command_log "ALTERAR IP E PORTA PRIMÁRIOS", codigo_telemetria
        output_persistence_command telemetry, CHANGE_PRIMARY_IP

      when "35"
        write_command_log "ALTERAR IP E PORTA SECUNDÁRIO", codigo_telemetria
        output_persistence_command telemetry, CHANGE_SECUNDARY_IP

      when "3D"
        write_command_log "ALTERAR HOST", codigo_telemetria
        output_persistence_command telemetry, CHANGE_HOST

      when "3E"
        write_command_log "ALTERAR PORTA DO HOST", codigo_telemetria
        output_persistence_command telemetry, CHANGE_PORT

      when "01"
        write_measures_log "A1", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A1"), CHANGE_FAIXA_TIMER

      when "02"
        write_measures_log "A2", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A2"), CHANGE_FAIXA_TIMER

      when "03"
        write_measures_log "A3", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A3"), CHANGE_FAIXA_TIMER

      when "04"
        write_measures_log "A4", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A4"), CHANGE_FAIXA_TIMER

      when "05"
        write_measures_log "A5", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A5"), CHANGE_FAIXA_TIMER

      when "06"
        write_measures_log "A6", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A6"), CHANGE_FAIXA_TIMER

      when "07"
        write_measures_log "A7", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A7"), CHANGE_FAIXA_TIMER

      when "08"
        write_measures_log "A8", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A8"), CHANGE_FAIXA_TIMER

      when "09"
        write_measures_log "A9", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A9"), CHANGE_FAIXA_TIMER

      when "0A"
        write_measures_log "A10", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A10"), CHANGE_FAIXA_TIMER

      when "0B"
        write_measures_log "A11", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A11"), CHANGE_FAIXA_TIMER

      when "0C"
        write_measures_log "A12", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A12"), CHANGE_FAIXA_TIMER

      when "0D"
        write_measures_log "A13", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A13"), CHANGE_FAIXA_TIMER

      when "0E"
        write_measures_log "A14", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A14"), CHANGE_FAIXA_TIMER

      when "0F"
        write_measures_log "A15", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A15"), CHANGE_FAIXA_TIMER

      when "10"
        write_measures_log "A16", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("A16"), CHANGE_FAIXA_TIMER

      when "11"
        write_measures_log "N01", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("N1"), CHANGE_FAIXA_TIMER

      when "12"
        write_measures_log "N02", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("N2"), CHANGE_FAIXA_TIMER

      when "13"
        write_measures_log "N03", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("N3"), CHANGE_FAIXA_TIMER

      when "14"
        write_measures_log "N04", codigo_telemetria
        output_persistence_measure_command telemetry, CODIGOS_MEDIDAS.key("N4"), CHANGE_FAIXA_TIMER

      when "15"
        write_measures_log "DIGITAIS", codigo_telemetria
        output_persistence_command telemetry, CHANGE_FAIXA_TIMER

      else
        logger.info "Telemetria: #{codigo_telemetria} avisa que processou o pacote: #{pacote}, mas... que p* de pacote é esse?!".blue
      end

    end

  end

  # Internal - Escreve no nog recebimento de mudanças de faixas e timmer pela telemetria
  #
  def self.write_measures_log medida, codigo_telemetria
    logger.info "Confirmação do recebimento do comando ALTERAR FAIXAS E TIMER, das medidas #{medida} por parte da telemetria #{codigo_telemetria}!".blue
  end

  # Internal - Escreve no nog recebimento de mudanças de commando pela telemetria
  #
  def self.write_command_log command, codigo_telemetria
    logger.info "Confirmação do recebimento do comando #{command}, por parte da telemetria #{codigo_telemetria}!".blue
  end

  # Internal : Método auxiliar do "processa_confirmacao_comandos", responsável por
  #            marcar um comando como "executado" na tabela de saída.
  #
  # saidas - lista de objetos da tabela saída que ainda não foram executados pela
  #          telemetria
  #
  def self.output_persistence_command telemetry_id, type_commmand
    saidas = Saida.where('cancelado = ? and data_processamento is ? and modelo_id = ? and telemetria_id = ? and comando = ?' , false, nil, 1, telemetry_id, type_commmand)
    saidas.each do |saida|
      saida.aguardando = false
      saida.processado = true
      saida.data_processamento = Time.now
      saida.aguardando_configuracao = true unless type_commmand == RESET_TELEMETRY && type_commmand == INSTANT_READING
      saida.save
    end
  end

  # Internal : Método auxiliar do "processa_confirmacao_comandos", responsável por
  #            marcar um comando como "executado" na tabela de saída, para as faixas
  #            que forem modificadas.
  #
  # saidas - lista de objetos da tabela saída que ainda não foram executados pela
  #          telemetria
  #
  def self.output_persistence_measure_command telemetry_id, local_id, type_commmand
    saidas = Saida.where('cancelado = ? and data_processamento is ? and modelo_id = ? and telemetria_id = ? and comando = ? and id_local = ?' , false, nil, 1, telemetry_id, type_commmand, local_id)
    saidas.each do |saida|
      saida.aguardando = false
      saida.processado = true
      saida.data_processamento = Time.now
      saida.aguardando_configuracao = true
      saida.save
    end
  end

  # Internal : Método auxiliar, responsável por extrair o código da telemetria de
  #            todos os pacotes da telemetria.
  #
  # Retorna o código da telemetria.
  def self.obtem_codigo_telemetria(pacote, inicio_telemetria_id = 0, fim_telemetria_id = 3)
    return pacote[inicio_telemetria_id..fim_telemetria_id]
  end

  # Internal : Método auxiliar, responsável por extrair o firmware da telemetria
  #            de um pacote de configuracao.
  #
  # Retorna o firmware da telemetria.
  def self.obtem_firmware(pacote, inicio_firmware = 6, fim_firmware = 9)
    return pacote[inicio_firmware..fim_firmware]
  end

  # Internal : Método auxiliar, responsável por extrair o nível de sinal da
  #            telemetria de um pacote de alguns tipos de pacote, dentre eles
  #            (inicializacão, leitura instântanea).
  #
  # Retorna o nível de sinal da telemetria.
  def self.obtem_nivel_sinal(pacote, inicio_nivel_sinal = 74, fim_nivel_sinal = 78, base_subtracao = 65536)
    return pacote[inicio_nivel_sinal...fim_nivel_sinal].to_i(BASE_HEXA) - base_subtracao
  end

  # Internal : Método auxiliar, responsável por extrair o tipo do pacote da
  #            telemetria de todos os pacotes da telemetria.
  #
  # Retorna o tipo do pacote da telemetria.
  def self.obtem_tipo_pacote(pacote, inicio_id = 4, fim_id = 5)
    id_pacote = pacote[inicio_id..fim_id]

    return id_pacote.blank? ? '9999' : id_pacote
  end

  # Internal : Encontra a telemetria que esta comunicando naquele momento, solicita
  #            a atualização dos dados da mesma.
  #
  # Retorna uma menssagem de sucesso ou de erro, dependendo da execução do método.
  def self.find_and_update_telemetria(params)
    telemetria = TelemetriaController::find_telemetria params
    result, id_telemetria = TelemetriaController::atualiza_telemetria telemetria, params

    if result
      logger.info "Dados da telemetria #{params[:codigo_telemetria]} atualizados com sucesso.".blue
      return true, id_telemetria
    else
      logger.info "Houveram erros ao atualizar dados da telemetria #{params[:codigo_telemetria]}.".red
      return false
    end
  end

  # Internal : Percorre o pacote de "leitura_instantanea e inicialização",
  #            separando o conteúdo do mesmo em nome da medida e valor
  #
  #
  # Examples
  #
  #   obtem_medidas("499705818082808182818601000000000000000000000000000000C6800000000000000000FFCD13FF20FF75")
  #   # => {:A1=>51, :A2=>51, :A3=>51, :A4=>51, :A5=>51, :A6=>51, :A7=>51, :A8=>53, :A9=>0, :A10=>0, :A11=>0, :A12=>0, :A13=>0, :A14=>0, :A15=>0, :A16=>0, :N1=>0, :N2=>0, :N3=>0, :N4=>0, :D1=>0, :D2=>0, :D3=>0, :D4=>0}
  #
  # Retorna um Hash com as medidas ANALÓGICAS(A), NEGATIVAS(N) e DIGITAIS(D) e
  # seus respectivos valores.
  def self.obtem_medidas pacote
    init = 6
    index_A ||= 1
    index_N ||= 1
    index_D ||= 1
    leitura = Hash.new

    TOTAL_MEDIDAS.times do |i|
      case i + 1
      when 1..16
        leitura["A#{index_A}".to_sym] = BaseConverter.convert_value_dec pacote[init...init+2]
        index_A += 1

      when 17..20
        leitura["N#{index_N}".to_sym] = BaseConverter.convert_value_dec pacote[init...init+2]
        index_N += 1

      when 21..24
        leitura["D#{index_D}".to_sym] = pacote[init...init+2].hex
        index_D += 1
      end
      init += 2
    end
    return leitura
  end
end
