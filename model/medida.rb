class Medida < ActiveRecord::Base
  self.table_name = 'main.medidas'

  belongs_to :equipamento
  has_many :medidas_eventos
  has_many :faixas

  def self.create_medidas(id_telemetria, analogicas, negativas, digitais)
    equipamentos = Equipamento.where(telemetria_id: id_telemetria)
    equipamentos_evento = []

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

        if self.faixas_medidas_mudaram ultima_medida, medida, @faixa
          if medida.save
            self.persiste_faixas medida, @faixa, ultima_medida
          else
            Logging.error "problemas ao persistir a medida: #{medida.codigo_medida} da telemetria código: #{equipamento.telemetria.codigo}"
          end
        else
          Logging.warn "Não existem mudanças na configuração da medida: #{medida.codigo_medida} da telemetria código: #{equipamento.telemetria.codigo}"
        end
      end
    end
      equipamentos_evento = equipamentos_evento.uniq
      if equipamentos_evento.present?
        Evento::persiste_evento_configuracao equipamentos_evento
      else
        Logging.warn "É necessário cadastrar um equipamento e/ou pelo menos uma medida para que o evento de configuração seja persistido. Telemetria ID: #{id_telemetria}"
        return false
      end
  end

  # verifica se a media de configuração que esta tentando ser persistida possui algum dado novo ou é igual a ultima enviada
  # se retornar true é uma sinalização de que a faixa tem novos dados, se não ele é igual a última
  #
  # ultima_faixa: contem apenas a faixa verda, por que o pacote de configuração envia apenas esta
  #
  def self.faixas_medidas_mudaram ultima_medida, medida, faixa
    timer = medida.timer
    codigo = medida.codigo_medida
    ultima_medida ? (ultimas_faixas = self.busca_faixas_medida ultima_medida.id) : ultimas_faixas = []

    ultima_faixa = ultimas_faixas.first
    if ultima_faixa.present?
      if (ultima_faixa.minimo.to_f == faixa[:minimo]) && (ultima_faixa.maximo.to_f == faixa[:maximo]) && (timer == ultima_medida.timer)
        return false
      else
        return true
      end
    else
      return true
    end
  end

  def self.busca_faixas_medida medida_id
    faixas = Faixa.where(medida_id: medida_id).order(:status_faixa)
  end

  def self.persiste_faixas medida, faixa, ultima_medida
    ultima_medida ? (ultimas_faixas = self.busca_faixas_medida ultima_medida.id) : ultimas_faixas = []
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
end
