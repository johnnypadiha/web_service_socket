require 'pp'
class Medida < ActiveRecord::Base
  self.table_name = 'main.medidas'

  belongs_to :equipamento
  has_many :medidas_eventos
  has_many :faixas

  has_many :medidas_equipamentos

  has_many :equipamentos,
    class_name: "Equipamento",
    dependent: :destroy,
    :through => :medidas_equipamentos

  def self.create_medidas(id_telemetria, analogicas, negativas, digitais)
    equipamentos = Equipamento.where(telemetria_id: id_telemetria)
    unless equipamentos.blank?
      equipamentos_evento = []
      @mudanca_faixa = false
      @medidas = []
      @medidas_evento = []
      @ultimas_medidas_evento = []

      equipamentos.each do |equipamento|
        equipamentos_evento << equipamento.id
        total_medidas_telemetria = [analogicas, negativas, digitais].inject(&:merge)

        #
        codigos_equipamentos_unicos =
          equipamento.equipamentos_codigos
                     .where(disponivel_ambiente: false)
                     .where(equipamento_id: equipamento.id)
                     .includes(:codigo)
        codigos_equipamentos_comuns =
          equipamento.equipamentos_codigos
                     .where(disponivel_ambiente: true)
                     .where(equipamento_id: equipamento.id)
                     .includes(:codigo)
        #
        codigos_equipamentos_completo = { comuns: codigos_equipamentos_comuns, unicas: codigos_equipamentos_unicos}

        codigos_equipamentos_completo.each do |k, v|
          pacote = nil
          comum = nil
          if k.to_s == 'comuns'
            pacote = v
            comum = true
          else
            pacote = v
            comum = false
          end
          mudanca_faixa, medidas_evento, ultimas_medidas_evento, medidas_faixas =
            Medida.processar_valores_configuracao(total_medidas_telemetria, pacote, equipamento, @mudanca_faixa, comum)
            @mudanca_faixa = mudanca_faixa
            @medidas_evento << medidas_evento
            @ultimas_medidas_evento << ultimas_medidas_evento
            @medidas << medidas_faixas
        end
        pp @medidas
      end

        if @mudanca_faixa
          @medidas.compact.each do |medida|
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
  def self.extrair_medidas(pacote, codigo)
    if pacote.has_key?(codigo)
      return pacote[codigo][:timer], pacote[codigo]
    end
  end

  def self.processar_valores_configuracao(total_medidas_telemetria, medidas_equipamento, equipamento, mudanca_faixa, medidas_comum = false)
    medidas_equipamento.each do |codigo_by_equipamento|
      timer, @faixa = Medida.extrair_medidas(total_medidas_telemetria, codigo_by_equipamento.codigo.codigo)
      # Não consigo pegar esta medida pois não tenho o ID do equipamento
      ultima_medida = Medida.where(equipamento_id: equipamento, id_local: codigo_by_equipamento.codigo.id).last

      indice = codigo_by_equipamento.codigo.id
      indice = indice - 1

      medida = Medida.inicializar_medida ultima_medida, codigo_by_equipamento, equipamento.id, medidas_comum, indice, timer


      if Medida::faixas_medidas_mudaram ultima_medida, medida, @faixa
        mudanca_faixa = true
      end
      medidas_evento = medida
      ultimas_medidas_evento = ultima_medida
      medidas_faixas = {medida: medida, faixa: @faixa, ultima_medida: ultima_medida}
        p "mudança de faixa"
        p mudanca_faixa
        p "mudança evento"
        p medidas_evento
        p "mudança medidas_evento"
        p ultimas_medidas_evento
        p "medida faixa"
        p medidas_faixas

      return mudanca_faixa, medidas_evento, ultimas_medidas_evento, medidas_faixas
    end
  end

  def self.inicializar_medida(ultima_medida, codigo_by_equipamento, equipamento_id, medidas_comum, indice, timer)
    equipamento_id = nil if medidas_comum
    gauge =
      if ultima_medida.present?
        ultima_medida.gauge.present? ? ultima_medida.gauge : 'digital'
      else
        'digital'
      end

    medida = Medida.new
    medida.equipamento_id       = equipamento_id
    medida.indice               = ultima_medida.present? ? ultima_medida.indice : indice
    medida.disponivel_ambiente  = codigo_by_equipamento.disponivel_ambiente
    medida.nome                 = ultima_medida.present? ? ultima_medida.nome : codigo_by_equipamento.codigo.codigo
    medida.unidade_medida       = ultima_medida.present? ? ultima_medida.unidade_medida : nil
    medida.reporte_medida_id    = ultima_medida.present? ? ultima_medida.reporte_medida_id : nil
    medida.gauge                = gauge
    medida.temperatura_ambiente = codigo_by_equipamento.disponivel_temperatura
    medida.grandeza             = ultima_medida.present? ? ultima_medida.grandeza : nil
    medida.divisor              = ultima_medida.present? ? ultima_medida.divisor : nil
    medida.multiplo             = ultima_medida.present? ? ultima_medida.multiplo : nil
    medida.reporte_medida_id    = ultima_medida.present? ? ultima_medida.reporte_medida_id : nil
    medida.id_local             = codigo_by_equipamento.codigo.id
    medida.timer                = timer

    medida
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
