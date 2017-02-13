class SelecionarPacote
  attr :codigo_pacote, :status_faixa, :codigo_atual

  def initialize(args = {})
    @codigo_pacote = args[:codigo_pacote]
    @status_faixa = args[:status_faixa]
    @codigo_atual = args[:codigo_atual]
  end

  # Internal: Seleciona o pacote conforme o tipo
  #
  # codigo_pacote - Codigo do pacote a ser processado
  #
  # Retorna a referencia do pacote
  # TODO: Em desuso, remover após os devidos testes.
  def seleciona_pacote
    case codigo_pacote.to_i
    when PERIODICO_OK, PERIODICO_ALARMADO
      SelecionarPacote.filtrar_codigo_evento({ status_faixa: status_faixa, ok: 8, alerta: 10, alarme: 9, codigo_atual: codigo_atual })
    when LEITURA_INSTANTANEA
      SelecionarPacote.filtrar_codigo_evento({ status_faixa: status_faixa, ok: 11, alerta: 20, alarme: 19, codigo_atual: codigo_atual })
    when ALARME_INSTANTANEO
      SelecionarPacote.filtrar_codigo_evento({ status_faixa: status_faixa, ok: 25, alerta: 26, alarme: 14, codigo_atual: codigo_atual })
    when NORMALIZACAO
      SelecionarPacote.filtrar_codigo_evento({ status_faixa: status_faixa, ok: 15, alerta: 23, alarme: 24, codigo_atual: codigo_atual })
    else
      # TODO: 'Implementar'
    end
  end

  # Internal : Gera o tipo do pacote
  #
  # codigo_evento - Inteiro que armazena o codigo do evento enviado pela telemetria
  # tipos - Todos os tipos de medidas disponiveis no evento
  #
  # Retorna a referencia do pacote.
  def self.gerar_tipo_pacote(codigo_evento, tipos)
    case codigo_evento
    when PERIODICO_OK, PERIODICO_ALARMADO
      if tipos.include?(ALARME)
        PACOTE_PERIODICO_ALARME
      elsif tipos.include?(ALERTA)
        PACOTE_PERIODICO_ALERTA
      elsif tipos.include?(OK)
        PACOTE_PERIODICO_OK
      end
    when LEITURA_INSTANTANEA
      if tipos.include?(ALARME)
        LEITURA_INSTANTANEA_ALARME
      elsif tipos.include?(ALERTA)
        LEITURA_INSTANTANEA_ALERTA
      elsif tipos.include?(OK)
        LEITURA_INSTANTANEA_OK
      end
    when ALARME_INSTANTANEO
      if tipos.include?(ALARME)
        PACOTE_ALARME
      elsif tipos.include?(ALERTA)
        PACOTE_ALERTA
      elsif tipos.include?(OK)
        PACOTE_NORMALIZACAO
      end
    when NORMALIZACAO
      if tipos.include?(ALARME)
        PACOTE_NORMALIZACAO_ALARME
      elsif tipos.include?(ALERTA)
        PACOTE_NORMALIZACAO_ALERTA
      elsif tipos.include?(OK)
        PACOTE_NORMALIZACAO
      end
    end
  end


  # Internal: Filtra o codigo do evento
  #
  # args - hash contendo os parâmetros necessários para a execução.
  # codigo_evento - Inteiro contendo o código do evento
  #
  # Retorna o tipo do pacote
  def self.filtrar_codigo_evento(args = {})
    case args[:status_faixa].to_i
    when OK
      codigo_evento =
      if args[:codigo_atual].to_i == args[:alarme].to_i || args[:codigo_atual].to_i == args[:alerta].to_i
        args[:codigo_atual].to_i == args[:alarme].to_i ? args[:alarme].to_i : args[:alerta].to_i
      else
        args[:ok].to_i
      end
    when ALERTA
      codigo_evento = args[:codigo_atual].to_i == args[:alarme].to_i ? args[:alarme].to_i : args[:alerta].to_i
    when ALARME
      codigo_evento = args[:alarme].to_i
    end
  end
end
