class AlarmeNormalizacao
  attr :pacote

  def initialize(args = {})
    @pacote = args[:pacote]
  end

  # Internal: Verifica se ouve alteração de faixa
  #
  # medidas_eventos_colecao - Array com a coleção de medidas
  # novo_pacote - Array com o novo pacote a ser gerado.
  #
  # Retorna um novo pacote.
  def detectar_alteracao
    medidas_eventos_colecao = []
    novo_pacote = []
    pacote.each do |pack|
      equipamento = Equipamento.find(pack[:id_equipamento])

      if equipamento.medidas_equipamento(pack).present?
        equipamento.medidas_equipamento(pack).each do |medida|
          faixa_atual = medida.faixas.select {|s| pack[CODIGOS_MEDIDAS[medida.id_local].to_sym].to_i >= s.minimo.to_i && pack[CODIGOS_MEDIDAS[medida.id_local].to_sym].to_i <= s.maximo.to_i}.first
          status_faixa = faixa_atual.present? ? faixa_atual.status_faixa : ALARME

          medida_evento = {
                            medida_id: medida.id,
                            valor: pack[CODIGOS_MEDIDAS[medida.id_local].to_sym].to_i,
                            status_faixa: status_faixa,
                            id_local: medida.id_local
                          }

          medidas_eventos_colecao << medida_evento
        end

        ultimas_medidas_evento = MedidasEvento.obter_ultimas_medidas_evento medidas_eventos_colecao, pack[:id_equipamento]

        mudou_faixa, tipo_pacote = AlarmeNormalizacao.detecta_mudanca_faixa ultimas_medidas_evento, medidas_eventos_colecao

        if mudou_faixa
          codigo_pacote = AlarmeNormalizacao.obter_tipo_pacote tipo_pacote, medidas_eventos_colecao
          pack[:tipo_pacote] = codigo_pacote
          novo_pacote << pack
        else
          logger.info "A Telemetria #{pack[:codigo_telemetria]} Enviou Um "\
                       "pacote de normalização  para o equipamento: "\
                       "foi recebido e ignorado, Nome : #{equipamento.nome} / ID: #{equipamento.id}"\
                       " pois não ocorreram mudanças nas faixas".yellow
        end

      else
        logger.info  "A Telemetria #{pack[:codigo_telemetria]} Enviou Um "\
                     "pacote e o mesmo foi ignorado, "\
                     "Pois ainda não existem medidas relacionadas ao equipamento "\
                     "Nome : #{equipamento.nome} / ID: #{equipamento.id}".yellow
      end
    end

    novo_pacote
  end

  # Internal: Detecta se ouve mudança de faixa para alguma medida
  #
  # ultimas_medidas_evento - Objecto do tipo medidaEvento contendo as ultimas medidas
  # medidas_colecao - Objeto contendo as novas medidas a serem comparadas.
  # tipo_pacote - integer que armazena o tipo do pacote em medidas_colecao
  # mudou_faixa - Boolean que informa se houve mudança na faixa
  #
  # Retorna o tipo do pacote e se ele é um alarme.
  def self.detecta_mudanca_faixa(ultimas_medidas_evento, medidas_colecao)
    tipo_pacote = 0
    mudou_faixa = false
    ultimas_medidas_evento.each do |medida_anterior|
      medidas_colecao.each do |medida_atual|
        if medida_atual[:medida_id].to_i == medida_anterior.medida_id
          unless medida_atual[:status_faixa].to_i == medida_anterior.status_faixa.to_i
            mudou_faixa = true
            case medida_atual[:status_faixa].to_i
            when OK
              tipo_pacote = PACOTE_NORMALIZACAO unless tipo_pacote == PACOTE_ALERTA && tipo_pacote == PACOTE_ALARME
            when ALERTA
              tipo_pacote = PACOTE_ALERTA unless tipo_pacote == PACOTE_ALARME
            when ALARME
              tipo_pacote = PACOTE_ALARME
            end
          end
        end
      end
    end

    return mudou_faixa, tipo_pacote
  end

  # Internal: Gera o tipo do pacote
  #
  # tipo_pacote - Integer contendo o ultimo tipo do pacote calculado
  # pacote - hash contendo a leitura atual
  #
  # Retrna o tipo do pacote
  def self.obter_tipo_pacote(tipo_pacote, pacote)
    medidas_em_alarme = pacote.select {|s| s[:status_faixa].to_i == ALARME}
    medidas_em_alerta = pacote.select {|s| s[:status_faixa].to_i == ALERTA}
    medidas_normalizadas = pacote.select {|s| s[:status_faixa].to_i == OK}
    case tipo_pacote.to_i
    when PACOTE_NORMALIZACAO
      tipo_pacote = PACOTE_NORMALIZACAO_ALERTA if medidas_em_alerta.present?
      tipo_pacote = PACOTE_NORMALIZACAO_ALARME if medidas_em_alarme.present?
    when PACOTE_ALERTA
      tipo_pacote = PACOTE_ALERTA_OK if medidas_normalizadas.present?
      tipo_pacote = PACOTE_ALERTA_ALARME if medidas_em_alarme.present?
    end

    tipo_pacote
  end
end
