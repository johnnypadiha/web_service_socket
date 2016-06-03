require_relative '../service/processar_pacotes.rb'
class Pacotes
  def self.processador(pacote)
    pacote = Pacotes::formatador(pacote)
    tipo_pacote = ProcessarPacotes::obtem_tipo_pacote pacote

    case tipo_pacote.to_i
    when 0
      logger.info "\n"
        logger.info("Periódico OK")
        medidas = ProcessarPacotes.leituras_instantanea pacote
        logger.info medidas
      logger.info "\n"
    when 1
      logger.info "\n"
        logger.info("Periódico Alarmado")
        medidas = ProcessarPacotes.leituras_instantanea pacote
        logger.info medidas
      logger.info "\n"
    when 3
        print('Configuração')
        analogicas_brutas = pacote[10..73]
        negativas_brutas = pacote[74..90]
        digitais_brutas = pacote[91..91]

        timers_analogicas = pacote[92..123]
        timers_negativas = pacote[124..131]
        timers_digitais = pacote[132..140]
        timer_periodico = pacote[148..151]

        operadora = pacote[152..153]

        ip1_1octeto = pacote[154..155]
        ip1_2octeto = pacote[156..157]
        ip1_3octeto = pacote[158..159]
        ip1_4octeto = pacote[160..161]
        porta_ip1 = pacote[162..165]

        ip2_1octeto = pacote[166..167]
        ip2_2octeto = pacote[168..169]
        ip2_3octeto = pacote[170..171]
        ip2_4octeto = pacote[172..173]
        porta_ip2 = pacote[174..177]
        host = pacote[178..183]
        porta_dns = pacote[184..187]

        timer_periodico = timer_periodico.hex

        ip1_1octeto = ip1_1octeto.hex
        ip1_2octeto = ip1_2octeto.hex
        ip1_3octeto = ip1_3octeto.hex
        ip1_4octeto = ip1_4octeto.hex
        porta_ip1 = porta_ip1.hex

        ip2_1octeto = ip1_1octeto.hex
        ip2_2octeto = ip1_2octeto.hex
        ip2_3octeto = ip1_3octeto.hex
        ip2_4octeto = ip1_4octeto.hex
        porta_ip2 = porta_ip1.hex

        operadora = operadora.hex
        case operadora.to_i
        when 1
          p operadora = "TIM"
        when 2
          p operadora = "VIVO M2M / SMARTCENTER"
        when 3
          p operadora = "BRASIL TELECOM"
        when 4
          p operadora = "VIVO"
        when 5
          p operadora = "OI"
        else
          p operadora
        end

        porta_dns = porta_dns.hex
        if host.hex == 0
          host = host.hex
        else
          host = host.split.pack('H*').gsub("\0","")
        end

        Pacotes::configuracao(analogicas_brutas, negativas_brutas, digitais_brutas, timers_analogicas, timers_negativas, timers_digitais, timer_periodico)
        firmware = ProcessarPacotes::obtem_firmware pacote
    when 4
      logger.info "\n"
        logger.info ("Inicialização")
        inicializacao = ProcessarPacotes.inicializacao pacote
        logger.info inicializacao
      logger.info "\n"
    when 5
      logger.info "\n"
        logger.info("Leitura Instantânea")
        medidas = ProcessarPacotes.leituras_instantanea pacote
        logger.info medidas
      logger.info "\n"
    when 7
        print('Em contagem para alarmar')
    when 8
      logger.info "\n"
        logger.info("Restauração Instantânea")
        medidas = ProcessarPacotes.leituras_instantanea(pacote)
        logger.info medidas
      logger.info "\n"
    when 9
      logger.info "\n"
        logger.info("Alarme Instantâneo")
        medidas = ProcessarPacotes.leituras_instantanea(pacote)
        logger.info medidas
      logger.info "\n"
    when 9999
      logger.info "\n"
      logger.info "ID RECEBIDO <#{pacote}>"
      logger.info "\n"
    else
        print("pacote tipo: #{tipo_pacote}, ainda não suportado pelo WebService")
    end

  end

  def self.formatador(pacote)
    pacote = pacote.chomp
    pacote = pacote.tr!('<', '')
    pacote = pacote.tr!('>', '')
  end

  def self.configuracao(analogicas_brutas, negativas_brutas, digitais_brutas, timers_analogicas, timers_negativas, timers_digitais, timer_periodico)

    digitais_bin = digitais_brutas.hex.to_s(2)

    digitais_bin = digitais_bin.rjust(4,'0')

    digitais_bin = digitais_bin[0..3]

    timer_periodico = timer_periodico.hex / 60

    cont = 0
    time_cont = 0
    medidas = Hash.new

    16.times do |i|
      medidas[:"A#{i+1}-min"] = analogicas_brutas[cont ... cont+2].to_i(16) * 100 / 255
      medidas[:"A#{i+1}-max"] = analogicas_brutas[cont+2 ... cont+4].to_i(16) * 100 / 255
      medidas[:"A#{i+1}-max"] = analogicas_brutas[cont+2 ... cont+4].to_i(16) * 100 / 255
      medidas[:"A#{i+1}-timer"] = timers_analogicas[time_cont ... time_cont+2].hex.to_s(10)

      time_cont = time_cont+2
      cont = cont+4
    end

    cont = 0
    time_cont = 0

    4.times do |i|
      medidas[:"N#{i+1}-min"] = negativas_brutas[cont ... cont+2].to_i(16) * 100 / 255
      medidas[:"N#{i+1}-max"] = negativas_brutas[cont+2 ... cont+4].to_i(16) * 100 / 255
      medidas[:"N#{i+1}-timer"] = timers_negativas[time_cont ... time_cont+2].hex.to_s(10)
      time_cont = time_cont+2
      cont = cont+4
    end

    time_cont = 0

    4.times do |i|
      medidas[:"D#{i+1}-normal"] = digitais_bin[i-1]
      medidas[:"D#{i+1}-timer"] = timers_digitais[time_cont ... time_cont+2].hex.to_s(10)
      time_cont = time_cont+2
    end

     medidas.each do |k,v|
       #logger.info "#{k} => #{v}"
       #p "#{k} => #{v}"
     end

  end
end
