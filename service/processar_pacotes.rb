# encoding: utf-8
require_relative '../service/processar_pacotes.rb'
class ProcessarPacotes
  # Alarme Instantâneo
  # Leitura Instantânea
  # Periodico
  def self.leituras_instantanea(pacote)
    init = 6
    index_A ||= 1
    index_N ||= 1
    index_D ||= 1
    medidas = Hash.new
    leitura = Hash.new
    medidas[:codigo_telemetria] = ProcessarPacotes::obtem_telemetria_id pacote
    medidas[:tipo_pacote] = (ProcessarPacotes::obtem_tipo_pacote pacote).to_i
    leitura[:DBM] = if pacote.size == 72
      ProcessarPacotes::obtem_nivel_sinal(pacote, 58, 62)
    else
      ProcessarPacotes::obtem_nivel_sinal pacote
    end

    24.times do |i|
      case i + 1
      when 1..16
        leitura["A#{index_A}".to_sym] = BaseConverter.convert_value_dec pacote[init...init+2]

        index_A += 1
      when 17..20
        leitura["N#{index_N}".to_sym] = BaseConverter.convert_value_dec pacote[init...init+2]

        index_N += 1
      when 21..24
        leitura["D#{index_D}".to_sym] = BaseConverter.convert_value_dec pacote[init...init+2]

        index_D += 1
      end
      init += 2
    end
    medidas[:leituras] = leitura
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
    return pacote[inicio_nivel_sinal...fim_nivel_sinal].to_i(BASE_HEXA) - base_subtracao
  end

  def self.obtem_tipo_pacote(pacote, inicio_id = 4, fim_id = 5)
    id_pacote = pacote[inicio_id..fim_id]

    return id_pacote.blank? ? '9999' : id_pacote
  end
end
