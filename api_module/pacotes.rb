class Pacotes
  def self.processador(pacote)
    pacote = Pacotes::formatador(pacote)
    id_telemetria = pacote[0..3]
    tipo_pacote = pacote[4..5]
    p "id_telemetria: #{id_telemetria}"
    p "tipo_pacote: #{tipo_pacote}"
    p pacote
  end

  def self.formatador(pacote)
    pacote = pacote.chomp!
    pacote = pacote.tr!('<', '')
    pacote = pacote.tr!('>', '')
  end
end
