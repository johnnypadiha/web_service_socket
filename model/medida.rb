class Medida < ActiveRecord::Base
  self.table_name = 'main.medidas'

  belongs_to :equipamento
  has_many :medidas_eventos
  has_many :faixas

  def self.create_medidas(id_telemetria, analogicas, negativas, digitais)
    equipamentos = Equipamento.where(telemetria_id: id_telemetria)
    unless equipamentos.blank?
      equipamentos_evento = []
      @mudanca_faixa = false
      @medidas = []
      @medidas_evento = []
      @ultimas_medidas_evento = []

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
          ultima_medida = Medida.where(equipamento_id: equipamento, id_local: codigo_by_equipamento.codigo.id).last

          ultima = ultima_medida.present?
          indice = codigo_by_equipamento.codigo.id
          indice = indice - 1
          gauge =
            if ultima
              ultima_medida.gauge.present? ? ultima_medida.gauge : 'digital'
            else
              'digital'
            end
          medida.equipamento_id       = equipamento.id
          medida.indice               = ultima ? ultima_medida.indice : medida.indice = indice
          medida.disponivel_ambiente  = codigo_by_equipamento.disponivel_ambiente
          medida.nome                 = ultima ? ultima_medida.nome : codigo_by_equipamento.codigo.codigo
          medida.unidade_medida       = ultima ? ultima_medida.unidade_medida : nil
          medida.reporte_medida_id    = ultima ? ultima_medida.reporte_medida_id : nil
          medida.gauge                = gauge
          medida.temperatura_ambiente = codigo_by_equipamento.disponivel_temperatura
          medida.grandeza             = ultima ? ultima_medida.grandeza : nil
          medida.divisor              = ultima ? ultima_medida.divisor : nil
          medida.multiplo             = ultima ? ultima_medida.multiplo : nil
          medida.reporte_medida_id    = ultima ? ultima_medida.reporte_medida_id : nil
          medida.id_local             = codigo_by_equipamento.codigo.id

          if Medida::faixas_medidas_mudaram ultima_medida, medida, @faixa
            @mudanca_faixa = true
          end
          @medidas_evento << medida
          @ultimas_medidas_evento << ultima_medida
          @medidas_faixas = {medida: medida, faixa: @faixa, ultima_medida: ultima_medida}
          @medidas << @medidas_faixas
        end
      end

        if @mudanca_faixa
          @medidas.each do |medida|
             medida[:medida].save
              Medida::persiste_faixas medida[:medida], medida[:faixa], medida[:ultima_medida]
          end
          evento = @medidas_evento
        else
          evento = @ultimas_medidas_evento
          Logging.warn "Não existem mudanças na configuração da telemetria ID #{id_telemetria}"
        end

        equipamentos_evento = equipamentos_evento.uniq
        if equipamentos_evento.present?
          Evento::persiste_evento_configuracao equipamentos_evento, evento
        else
          Logging.warn "É necessário cadastrar um equipamento e/ou pelo menos uma medida para que o evento de configuração seja persistido. Telemetria ID: #{id_telemetria}"
          return false
        end
      else
        Logging.warn "Nenhum equipamento cadastrado para Telemetria ID: #{id_telemetria}"
      end
  end

  # verifica se a media de configuração que esta tentando ser persistida possui algum dado novo ou é igual a ultima enviada
  # se retornar true é uma sinalização de que a faixa tem novos dados, se não ele é igual a última
  #
  # ultima_faixa: contem apenas a faixa verda, por que o pacote de configuração envia apenas esta
  #
  def self.faixas_medidas_mudaram ultima_medida, medida, faixa
    timer = medida.timer
    codigo = medida.id_local
    ultima_medida ? (ultimas_faixas = Medida::busca_faixas_medida ultima_medida.id) : ultimas_faixas = []
    ultima_faixa = ultimas_faixas.first

      if ultima_faixa.present?
        if medida.id_local >= INICIO_DIGITAIS and medida.id_local <= FIM_DIGITAIS
            if (ultima_faixa.minimo.to_f == faixa[:normal].to_f) && (ultima_faixa.maximo.to_f == faixa[:normal].to_i.to_f + 0.99) && (timer == ultima_medida.timer)
              return false
            else
              return true
            end
        else
          if (ultima_faixa.minimo.to_f == faixa[:minimo].to_f) && (ultima_faixa.maximo.to_f == faixa[:maximo].to_f) && (timer == ultima_medida.timer)
            return false
          else
            return true
          end
        end
      else
        return true
      end
  end

  def self.busca_faixas_medida medida_id
    faixas = Faixa.where(medida_id: medida_id).order(:status_faixa)
  end

  def self.persiste_faixas medida, faixa, ultima_medida
    ultima_medida ? (ultimas_faixas = Medida::busca_faixas_medida ultima_medida.id) : ultimas_faixas = []

    if medida.id_local >= INICIO_DIGITAIS and medida.id_local <= FIM_DIGITAIS
      Faixa.create(medida_id: medida.id, status_faixa: OK, disable: false, minimo: faixa[:normal], maximo: faixa[:normal].to_i + 0.99 )
      Faixa.create(medida_id: medida.id, status_faixa: ALERTA, disable: false, minimo: 50, maximo: 51 )
      normal = faixa[:normal] == 0 ? 1 : 0
      Faixa.create(medida_id: medida.id, status_faixa: ALARME, disable: false, minimo: normal, maximo: normal.to_i + 0.99 )
    else
      Faixa.create(medida_id: medida.id, status_faixa: OK, disable: false, minimo: faixa[:minimo], maximo: faixa[:maximo] )
      Faixa.create(medida_id: medida.id, status_faixa: ALERTA, disable: false, minimo: ultimas_faixas[1] ? ultimas_faixas[1].minimo : 0, maximo: ultimas_faixas[1] ? ultimas_faixas[1].maximo : 0 )
      Faixa.create(medida_id: medida.id, status_faixa: ALARME, disable: false, minimo: ultimas_faixas[2] ? ultimas_faixas[2].minimo : 0, maximo: ultimas_faixas[2] ? ultimas_faixas[2].maximo : 0  )
    end
  end
end
