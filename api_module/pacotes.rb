require_relative '../service/processar_pacotes.rb'
class Pacotes
  def self.processador(pacote)
    pacote = Pacotes::formatador(pacote)
    tipo_pacote = pacote[4..5]
    p "id_telemetria: #{id_telemetria}"
    p "tipo_pacote: #{tipo_pacote}"

    case tipo_pacote.to_i
    when 0
        print('Periódico OK')
    when 1
        print('Periódico Alarmado')
    when 3
        print('Configuração')
        analogicas_brutas = pacote[10..73]
        negativas_brutas = pacote[74..90]
        digitais_brutas = pacote[91..91]

        timers_analogicas = pacote[92..123]
        timers_negativas = pacote[124..131]
        timers_digitais = pacote[132..140]

        # medidas_brutas = pacote[10..21]
        Pacotes::configuracao(analogicas_brutas, negativas_brutas, digitais_brutas, timers_analogicas, timers_negativas, timers_digitais)
        firmware = ProcessarPacotes::obtem_firmware pacote
    when 4
        print('Inicialização')
        inicializacao = ProcessarPacotes.inicializacao pacote
        logger.info inicializacao
    when 5
        print('Leitura Instantânea')
        medidas = ProcessarPacotes.leituras_instantanea(pacote)
        logger.info medidas
    when 7
        print('Em contagem para alarmar')
    when 8
        print('Restauração Instantânea')
    when 9
        print('Alarme Instantâneo')
        medidas = ProcessarPacotes.leituras_instantanea(pacote)
        logger.info medidas
    else
        print("pacote tipo: #{tipo_pacote}, ainda não suportado pelo WebService")
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

    digitais_bin = digitais_brutas.hex.to_s(2)

    digitais_bin = digitais_bin.rjust(4,'0')

    digitais_bin = digitais_bin[0..3]


    cont = 0
    time_cont = 0
    # medida = Array.new
    medidas = Hash.new
    # p dig

    16.times do |i|
      # medidas[:"A#{i+1}"] = analogicas_brutas[cont ... cont+4]
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
      # medidas[:"N#{i+1}"] = negativas_brutas[cont ... cont+4]
      medidas[:"N#{i+1}-min"] = negativas_brutas[cont ... cont+2].to_i(16) * 100 / 255
      medidas[:"N#{i+1}-max"] = negativas_brutas[cont+2 ... cont+4].to_i(16) * 100 / 255
      medidas[:"N#{i+1}-timer"] = timers_negativas[time_cont ... time_cont+2]#.hex.to_s(10)
      time_cont = time_cont+2
      cont = cont+4
    end

    # 20.times do |i|
    #   medida.push(med[cont ... cont+4])
    #   cont = cont+4
    # end

    time_cont = 0

    4.times do |i|
      # medidas[:"D#{i+1}"] = digitais_bin
      medidas[:"D#{i+1}-normal"] = digitais_bin[i-1]
      medidas[:"D#{i+1}-timer"] = timers_digitais[time_cont ... time_cont+2].hex.to_s(10)
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
