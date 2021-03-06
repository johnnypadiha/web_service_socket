class SepararMedidaEquipamento
  # Internal: Separa as medidas enviada pela telemetria por equipamento.
  #
  # medidas - Hash contendo os valores enviados pela telemetria
  # telemetria - Objeto do tipo Telemetria
  # eqm - Hash que irá armazenar as medidas referente a um determinado equipamento
  # evento - Array que irá armazenar os hash eqm
  # referencia_medidas - Objeto contendo os códigos das medidas do equipamento
  #
  # Retorna o array evento com as medidas devidamente separadas
  def self.obter_pacote_equipamento(medidas)
    telemetria = Telemetria.find_by_codigo(medidas[:codigo_telemetria])# || Telemetria.new
    eqm = {}
    evento = []
    if telemetria.blank?
      logger.info "Telemetria #{medidas[:codigo_telemetria]}" \
                  ' Não cadastrada'.yellow

    elsif telemetria.equipamentos.blank?
      logger.info 'Ainda não existem equipamentos associados a '\
                  "Telemetria #{medidas[:codigo_telemetria]}".yellow
    else
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
    end
    evento
  end
end
