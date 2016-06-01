class ProcessarPacotes
  # Alarme Instantâneo
  # Leitura Instantânea
  def self.leituras_instantanea(pacote)
    init = 6
    index_A ||= 1
    index_N ||= 1
    index_D ||= 1
    medidas = Hash.new

    medidas[:nivel_sinal] = ProcessarPacotes::obtem_nivel_sinal pacote
    24.times do |i|
      case i + 1
      when 1..16
        medidas["A#{index_A}".to_sym] = pacote[init...init+2].to_i(16) * 100 / 255

        index_A += 1
      when 17..20
        medidas["N#{index_N}".to_sym] = pacote[init...init+2].to_i(16) * 100 / 255

        index_N += 1
      when 21..24
        medidas["D#{index_D}".to_sym] = pacote[init...init+2].to_i(16) * 100 / 255

        index_D += 1
      end
      init += 2
    end

    medidas
  end

  def self.inicializacao(pacote)
    inicializacao = Hash.new
    inicializacao[:telemetria_id] = ProcessarPacotes::obtem_telemetria_id pacote
    inicializacao[:data] = Time.now
    inicializacao[:nivel_sinal] = ProcessarPacotes::obtem_nivel_sinal pacote
    inicializacao
  end

  def self.obtem_telemetria_id(pacote, inicio_telemetria_id = 0, fim_telemetria_id = 3)
    return pacote[inicio_telemetria_id..fim_telemetria_id]
  end

  def self.obtem_firmware(pacote, inicio_firmware = 6, fim_firmware = 9)
    return pacote[inicio_firmware..fim_firmware]
  end

  def self.obtem_nivel_sinal(pacote, inicio_nivel_sinal = 74, fim_nivel_sinal = 78, base_subtracao = 65536)
    return pacote[inicio_nivel_sinal...fim_nivel_sinal].to_i(16) - base_subtracao
  end
end
