require_relative '../service/processar_pacotes.rb'
class Pacotes
  def self.processador(pacote)
    pacote = Pacotes::formatador(pacote)
    tipo_pacote = ProcessarPacotes::obtem_tipo_pacote pacote

    case tipo_pacote.to_i
    when PERIODICO_OK
      logger.info "="*20
      logger.info("Periódico OK")
      medidas = ProcessarPacotes.leituras_instantanea pacote
      logger.info medidas
      Evento.persistir_evento medidas
      logger.info "="*20

    when PERIODICO_ALARMADO
      logger.info "="*20
      logger.info("Periódico Alarmado")
      medidas = ProcessarPacotes.leituras_instantanea pacote
      logger.info medidas
      Evento.persistir_evento medidas
      logger.info "="*20

    when CONFIGURACAO
      logger.info "="*20
      logger.info ("Configuração")
      ProcessarPacotes.configuracao pacote
      logger.info "="*20

    when INICIALIZACAO
      logger.info "="*20
      logger.info ("Inicialização")
      ProcessarPacotes.inicializacao pacote
      logger.info "="*20

    when LEITURA_INSTANTANEA
      logger.info "="*20
      logger.info("Leitura Instantânea")
      medidas = ProcessarPacotes.leituras_instantanea pacote
      logger.info medidas
      Evento.persistir_evento medidas
      logger.info "="*20

    when CONTAGEM_ALARMAR
      logger.info "="*20
      print('Em contagem para alarmar')
      logger.info "="*20

    when NORMALIZACAO
      logger.info "="*20
      logger.info("Restauração Instantânea")
      medidas = ProcessarPacotes.leituras_instantanea(pacote)
      logger.info medidas
      Evento.persistir_evento medidas
      logger.info "="*20

    when ALARME_INSTANTANEO
      logger.info "="*20
      logger.info("Alarme Instantâneo")
      medidas = ProcessarPacotes.leituras_instantanea(pacote)
      logger.info medidas
      Evento.persistir_evento medidas
      logger.info "="*20

    when ID_RECEBIDO
      logger.info "="*20
      logger.info "ID RECEBIDO <#{pacote}>"
      logger.info "="*20

    else
      logger.info "pacote tipo: #{tipo_pacote}, ainda não suportado pelo WebService".yellow
    end
  end

  def self.formatador(pacote)
    pacote = pacote.chomp
    pacote = pacote.tr!('<', '')
    pacote = pacote.tr!('>', '')
  end

end
