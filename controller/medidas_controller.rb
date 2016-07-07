class MedidasController

  def self.create_medidas(id_telemetria, analogicas, negativas, digitais)
    equipamentos = Equipamento.where(telemetria_id: id_telemetria)
    equipamentos_evento = []
    persistir_evento = false

    equipamentos.each do |equipamento|
      codigos_by_equipamento = EquipamentosCodigo.where(equipamento_id: equipamento.id).includes(:codigo)

      codigos_by_equipamento.each do |codigo_by_equipamento|

        equipamentos_evento.push(codigo_by_equipamento.equipamento_id)

        medida = Medida.new

        analogicas.each do |k, v|
          if k.to_s == codigo_by_equipamento.codigo.codigo.to_s
            medida.timer = v[:timer]
            @faixa = v
          end
        end
        negativas.each do |k, v|
          if k.to_s == codigo_by_equipamento.codigo.codigo.to_s
            medida.timer = v[:timer]
            @faixa = v
          end
        end
        digitais.each do |k, v|
          if k.to_s == codigo_by_equipamento.codigo.codigo.to_s
            medida.timer = v[:timer]
            @faixa = v
          end
        end
        ultima_medida = Medida.where(equipamento_id: equipamento, codigo_medida: codigo_by_equipamento.codigo.codigo).last

        medida.equipamento_id = equipamento.id
        ultima_medida ? medida.nome = ultima_medida.nome : medida.nome = codigo_by_equipamento.codigo.codigo
        ultima_medida ? medida.unidade_medida = ultima_medida.unidade_medida : medida.unidade_medida = nil
        ultima_medida ? medida.reporte_medida_id = ultima_medida.reporte_medida_id : medida.reporte_medida_id = nil
        medida.disponivel_ambiente = codigo_by_equipamento.disponivel_ambiente
        ultima_medida ? medida.gauge = ultima_medida.gauge : medida.gauge = nil
        medida.temperatura_ambiente = codigo_by_equipamento.disponivel_temperatura
        ultima_medida ? medida.grandeza = ultima_medida.grandeza : medida.grandeza = nil
        ultima_medida ? medida.divisor = ultima_medida.divisor : medida.divisor = nil
        ultima_medida ? medida.multiplo = ultima_medida.multiplo : medida.multiplo = nil
        ultima_medida ? medida.indice = ultima_medida.indice : medida.indice = nil
        medida.codigo_medida = codigo_by_equipamento.codigo.codigo
        ultima_medida ? medida.estado_normal = ultima_medida.estado_normal : medida.estado_normal = nil

        if medida.save
          persistir_evento = true
          self.persiste_faixas medida, @faixa, ultima_medida
        end

      end
    end
      equipamentos_evento = equipamentos_evento.uniq
      persistir_evento ? (self.persiste_evento_configuracao equipamentos_evento) : false
  end

  def self.persiste_faixas medida, faixa, ultima_medida
    ultima_medida ? ultimas_faixas = Faixa.where(medida_id: ultima_medida.id).order(:status_faixa) : ultimas_faixas = []
    if medida.codigo_medida[0] == 'D'
      Faixa.create(medida_id: medida.id, status_faixa: 1, disable: false, minimo: faixa[:normal], maximo: faixa[:normal].to_i + 0.99 )
      Faixa.create(medida_id: medida.id, status_faixa: 2, disable: false, minimo: 50, maximo: 51 )
      normal = faixa[:normal] == 0 ? 1 : 0
      Faixa.create(medida_id: medida.id, status_faixa: 3, disable: false, minimo: normal, maximo: normal.to_i + 0.99 )
    else
      Faixa.create(medida_id: medida.id, status_faixa: 1, disable: false, minimo: faixa[:minimo], maximo: faixa[:maximo] )
      Faixa.create(medida_id: medida.id, status_faixa: 2, disable: false, minimo: ultimas_faixas[1] ? ultimas_faixas[1].minimo : 0, maximo: ultimas_faixas[1] ? ultimas_faixas[1].maximo : 0 )
      Faixa.create(medida_id: medida.id, status_faixa: 3, disable: false, minimo: ultimas_faixas[2] ? ultimas_faixas[2].minimo : 0, maximo: ultimas_faixas[2] ? ultimas_faixas[2].maximo : 0  )
    end
  end

  def self.persiste_evento_configuracao(equipamentos_evento)
    id_configuracao_inicial_analogica = 21
    id_inicializacao_analogica = 20

    equipamentos_evento.each do |equipamento|
      ultima_inicializacao = Evento.where(status_id: id_inicializacao_analogica, equipamento_id: equipamento, created_at: Time.now().beginning_of_day..Time.now().end_of_day).includes(:status).last
      Evento.create(equipamento_id: equipamento, status_id: id_configuracao_inicial_analogica, reporte_faixa: false, reporte_energia: false, reporte_sinal: false, reporte_temperatura: false, nivel_sinal: ultima_inicializacao ? ultima_inicializacao.nivel_sinal : nil)
    end
  end

end
