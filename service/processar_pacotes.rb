# encoding: utf-8
require_relative '../service/processar_pacotes.rb'
require_relative '../controller/telemetria_controller.rb'

class ProcessarPacotes
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

  #digitais_bin = pega o Hexa converte para binario, garante que ele tenha 4 digitos e pega as 4 posições
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
      fundo_escala[:normal] = digitais_bin[i-1]
      fundo_escala[:timer] = configuracao_hex[:timers_digitais][time_cont ... time_cont+2].hex.to_s(BASE_DEC)
      digitais["D#{i+1}"] = fundo_escala
      time_cont = time_cont+2
    end
     return analogicas, negativas, digitais
  end

  # Internal - Responsável por verificar na tabela de saída se a resposta de uma
  #            uma telemetria pertence a algum comando que esta pendente na mesma
  #
  # codigo_telemetria - codigo da telemetria proveniente do pacote
  # telemetry - Chave primária da telemetria do qual pertence o pacote
  # pacote - pacote proveniente da telemetria contendo todos os dados de resposta
  #          de um comando que foi solicitado anteriormente
  #
  def self.processa_confirmacao_comandos pacote
    codigo_telemetria = ProcessarPacotes.obtem_codigo_telemetria pacote
    telemetry = Telemetria.select(:id).find_by_codigo(codigo_telemetria)
    pacote =  pacote[6..9]

    case pacote.to_s
    when "FFFF"
      logger.info "Confirmação do recebimento do comando LEITURA_INSTANTANEA por parte da telemetria #{codigo_telemetria}!".blue
      output_persistence_command telemetry, INSTANT_READING

    when "FFFE"
      logger.info "Confirmação do recebimento do comando RESET por parte da telemetria #{codigo_telemetria}!".blue
      output_persistence_command telemetry, RESET_TELEMETRY

    else
      logger.info "Telemetria: #{codigo_telemetria} avisa que processou o pacote: #{pacote}, mas... que p* de pacote é esse?".blue
    end
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
      saida.save
    end
  end

  def self.obtem_codigo_telemetria(pacote, inicio_telemetria_id = 0, fim_telemetria_id = 3)
    return pacote[inicio_telemetria_id..fim_telemetria_id]
  end

  def self.obtem_firmware(pacote, inicio_firmware = 6, fim_firmware = 9)
    return pacote[inicio_firmware..fim_firmware]
  end

  def self.obtem_nivel_sinal(pacote, inicio_nivel_sinal = 74, fim_nivel_sinal = 78, base_subtracao = 65536)
    return pacote[inicio_nivel_sinal...fim_nivel_sinal].to_i(BASE_HEXA) - base_subtracao
  end

  def self.obtem_tipo_pacote(pacote, inicio_id = 4, fim_id = 5)
    id_pacote = pacote[inicio_id..fim_id]

    return id_pacote.blank? ? '9999' : id_pacote
  end

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
