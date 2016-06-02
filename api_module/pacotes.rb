require_relative '../service/processar_pacotes.rb'
class Pacotes
  def self.processador(pacote)
    pacote = Pacotes::formatador(pacote)
    tipo_pacote = ProcessarPacotes::obtem_tipo_pacote pacote

    case tipo_pacote.to_i
    when PERIODICO_OK
      logger.info "="*20
      logger.info("Periódico OK")
      medidas = ProcessarPacotes.leituras_instantanea pacote
      logger.info medidas
      logger.info "="*20

    when PERIODICO_ALARMADO
      logger.info "="*20
      logger.info("Periódico Alarmado")
      medidas = ProcessarPacotes.leituras_instantanea pacote
      logger.info medidas
      logger.info "="*20

    when CONFIGURACAO
      logger.info "="*20
      print('Configuração')
      analogicas_brutas = pacote[10..73]
      negativas_brutas = pacote[74..90]
      digitais_brutas = pacote[91..91]

      timers_analogicas = pacote[92..123]
      timers_negativas = pacote[124..131]
      timers_digitais = pacote[132..140]

      Pacotes::configuracao(analogicas_brutas, negativas_brutas, digitais_brutas, timers_analogicas, timers_negativas, timers_digitais)
      firmware = ProcessarPacotes::obtem_firmware pacote
      logger.info "="*20

    when INICIALIZACAO
      logger.info "="*20
      logger.info ("Inicialização")
      ProcessarPacotes.inicializacao pacote
      logger.info "="*20

    when LEITURA_INSTANTANEA
      logger.info "="*20
      logger.info("Leitura Instantânea")
      medidas = ProcessarPacotes.leituras_instantanea pacote
      logger.info medidas
      logger.info "="*20

    when CONTAGEM_ALARMAR
      logger.info "="*20
      print('Em contagem para alarmar')
      logger.info "="*20

    when NORMALIZACAO
      logger.info "="*20
      logger.info("Restauração Instantânea")
      medidas = ProcessarPacotes.leituras_instantanea(pacote)
      logger.info medidas
      logger.info "="*20

    when ALARME_INSTANTANEO
      logger.info "="*20
      logger.info("Alarme Instantâneo")
      medidas = ProcessarPacotes.leituras_instantanea(pacote)
      logger.info medidas
      logger.info "="*20

    when ID_RECEBIDO
      logger.info "="*20
      logger.info "ID RECEBIDO <#{pacote}>"
      logger.info "="*20

    else
      logger.info "pacote tipo: #{tipo_pacote}, ainda não suportado pelo WebService".yellow
    end
  end

  def self.formatador(pacote)
    pacote = pacote.chomp
    pacote = pacote.tr!('<', '')
    pacote = pacote.tr!('>', '')
  end

  def self.configuracao(analogicas_brutas, negativas_brutas, digitais_brutas, timers_analogicas, timers_negativas, timers_digitais)
    # p "analógicas brutas: #{analogicas_brutas}"
    # p "\n NEGATIVAS brutas: #{negativas_brutas}"
    # p "\n TIMERs brutOs: #{timers_brutos.size}"
    # p "\n TIMERs ana: #{timers_analogicas}"
    p "\n TIMERs neg: #{timers_negativas}"
    # p "\n TIMERs digi: #{timers_digitais}"

    digitais_bin = digitais_brutas.hex.to_s(BASE_BIN)

    digitais_bin = digitais_bin.rjust(4,'0')

    digitais_bin = digitais_bin[0..3]


    cont = 0
    time_cont = 0
    # medida = Array.new
    medidas = Hash.new
    # p dig

    QTDE_ANALOGICAS.times do |i|
      medidas[:"A#{i+1}-min"] = BaseConverter.convert_value_dec analogicas_brutas[cont ... cont+2]
      medidas[:"A#{i+1}-max"] = BaseConverter.convert_value_dec analogicas_brutas[cont+2 ... cont+4]
      medidas[:"A#{i+1}-timer"] = timers_analogicas[time_cont ... time_cont+2].hex.to_s(BASE_DEC)

      time_cont = time_cont+2
      cont = cont+4
    end

    cont = 0
    time_cont = 0

    QTDE_NEGATIVAS.times do |i|
      medidas[:"N#{i+1}-min"] = BaseConverter.convert_value_dec negativas_brutas[cont ... cont+2]
      medidas[:"N#{i+1}-max"] = BaseConverter.convert_value_dec negativas_brutas[cont+2 ... cont+4]
      medidas[:"N#{i+1}-timer"] = timers_negativas[time_cont ... time_cont+2]
      time_cont = time_cont+2
      cont = cont+4
    end

    # 20.times do |i|
    #   medida.push(med[cont ... cont+4])
    #   cont = cont+4
    # end

    time_cont = 0

    QTDE_DIGITAIS.times do |i|
      medidas[:"D#{i+1}-normal"] = digitais_bin[i-1]
      medidas[:"D#{i+1}-timer"] = timers_digitais[time_cont ... time_cont+2].hex.to_s(BASE_DEC)
      time_cont = time_cont+2
    end

    # 24.times do |i|
    #   medida[i-1].push('t')
    # end

     medidas.each do |k,v|
    #    logger.info "#{k} => #{v}"
       p "#{k} => #{v}"
    #    logger.info "-----------------"
     end

    # min = med[cont,2]
    # max = med[cont+2,2]
    # timer = med[cont+2,2]
    # p "*"*5
    # p "min: #{min}"
    # p "*"*5
    # p "max: #{max}"
    # p "*"*5
    # p "timer: #{timer}"
    p "*"*5
  end
end
