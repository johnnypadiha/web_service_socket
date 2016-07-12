class AlarmeNormalizacao
  attr :pacote

  def initialize(args = {})
    @pacote = args[:pacote]
  end

  def detectar_alteracao
    medidas_eventos_colecao = []
    novo_pacote = []
    pacote.each do |pack|
      equipamento = Equipamento.find(pack[:id_equipamento])

      equipamento.medidas_equipamento(pack).each do |medida|
        faixa_atual = medida.faixas.select {|s| s.minimo.to_i >= pack[medida.codigo_medida.to_sym].to_i && s.maximo.to_i <= pack[medida.codigo_medida.to_sym].to_i}.first
        status_faixa = faixa_atual.present? ? faixa_atual.status_faixa : ALARME

        medida_evento = {
                          medida_id: medida.id,
                          valor: pack[medida.codigo_medida.to_sym],
                          status_faixa: status_faixa,
                          codigo_medida: medida.codigo_medida
                        }

        medidas_eventos_colecao << medida_evento
      end

      ultimas_medidas_evento = MedidasEvento.obter_ultimas_medidas_evento medidas_eventos_colecao

      if AlarmeNormalizacao.detecta_mudanca_faixa ultimas_medidas_evento, medidas_eventos_colecao
        novo_pacote << pack
      end
    end

    novo_pacote
  end

  def self.detecta_mudanca_faixa(ultimas_medidas_evento, medidas_colecao)
    tipo_pacote = 0
    mudou_faixa = false
    ultimas_medidas_evento.each do |medida_anterior|
      medidas_colecao.each do |medida_atual|
        if medida_atual[:medida_id].to_i == medida_anterior.medida_id
          mudou_faixa = true unless medida_atual[:status_faixa].to_i == medida_anterior.status_faixa.to_i
        end
      end

      break if mudou_faixa
    end

    mudou_faixa
  end
end
