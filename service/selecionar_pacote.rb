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
  def seleciona_pacote
    case codigo_pacote.to_i
    when PERIODICO_OK, PERIODICO_ALARMADO
      SelecionarPacote.filtrar_codigo_evento({status_faixa: status_faixa, ok: 8, alerta: 10, alarme: 9, codigo_atual: codigo_atual})
    when LEITURA_INSTANTANEA
      SelecionarPacote.filtrar_codigo_evento({status_faixa: status_faixa, ok: 11, alerta: 20, alarme: 19, codigo_atual: codigo_atual})
    else
      'Implementar'
    end
  end

  # Internal: Filtra o codigo do evento
  #
  # args - hash contendo os paramentros necessario para a execução.
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
