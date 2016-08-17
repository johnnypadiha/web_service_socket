class SepararMedidaEquipamento
  # Internal: Separa as medidas enviada pela telemetria por equipamento.
  #
  # medidas - Hash contendo os valores enviados pela telemetria
  # telemetria - Objeto do tipo Telemetria
  # eqm - Hash que irá armazenar as medidas referente a um determinado equipamento
  # evento - Array que irá armazenar os hash eqm
  #
  # Retorna o array evento com as medidas devidamente separadas
  def self.obter_pacote_equipamento(medidas)
    telemetria = Telemetria.find_by_codigo(medidas[:codigo_telemetria])
    eqm = {}
    evento = []
    telemetria.equipamentos.each do |equipamento|
      eqm[:id_equipamento] = equipamento.id
      referencia_medidas = equipamento.codigos || []
      eqm[:codigo_telemetria] = medidas[:codigo_telemetria]
      eqm[:DBM] = medidas[:DBM]
      eqm[:codigo_pacote] = medidas[:tipo_pacote]
      eqm[:telemetria_codigo] = telemetria.codigo
      referencia_medidas.each do |cod|
        eqm[cod.codigo.to_sym] = medidas[:leituras][cod.codigo.to_sym]
      end

      if equipamento.codigos.present?
        evento << eqm
      else
        logger.info "Um pacote foi recebido e ignorado, "\
                     "Pois ainda não existem medidas associadas ao equipamento "\
                     "Nome : #{equipamento.nome} / ID: #{equipamento.id}".yellow
      end
      eqm = {}
    end
    evento
  end
end
