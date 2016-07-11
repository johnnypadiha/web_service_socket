class SepararMedidaEquipamento
  def self.obter_pacote_equipamento(medidas)
    p medidas
    telemetria = Telemetria.find_by_codigo(medidas[:codigo_telemetria])
    eqm = {}
    evento = []
    telemetria.equipamentos.each do |equipamento|
      eqm[:id_equipamento] = equipamento.id
      referencia_medidas = equipamento.codigos || []
      eqm[:codigo_telemetria] = medidas[:codigo_telemetria]
      eqm[:DBM] = medidas[:DBM]
      eqm[:codigo_pacote] = medidas[:tipo_pacote]
      referencia_medidas.each do |cod|
        eqm[cod.codigo.to_sym] = medidas[:leituras][cod.codigo.to_sym]
      end

      evento << eqm
      eqm = {}
    end
    p evento
  end
end
