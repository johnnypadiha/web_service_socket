class ProcessarPacotes

  def self.alarme_instantaneo(pacote)
    init = 6
    index_A ||= 1
    index_N ||= 1
    index_D ||= 1
    medidas = Hash.new

    medidas[:nivel_sinal] = pacote[74...78].to_i(16) - 65536
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
end
