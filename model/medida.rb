class Medida < ActiveRecord::Base
  self.table_name = 'main.medidas'

  belongs_to :equipamento
  has_many :medidas_eventos
  has_many :faixas

  # Internal : Recebe o ID da telemetria e os dados dos pacotes e persiste as faixas
  #            o timer das medidas que vieram no pacote, uni esses dados com os
  #            os dados das últimas medidas e faixas já existentes no web para que
  #            o usuário não perca algumas informações que só existem no web.
  #            Após persistir os dados das medidas e faixas, chama um método que
  #            persistirá um evento com todos os valores zerados chamado de evento
  #            de cofiguração.
  #
  # @mudanca_faixa - flag que verifica se existiram mudanças nas faixas que vieram
  #                  da telemetria
  # @medidas[] - Array de objetos Medidas e Faixas que serão persistidos caso ocorreu
  #              alguma alteração de medidas e/ou faixas
  # @medidas_evento[] - Medidas que irão gerar o evento de Configuração
  # @ultimas_medidas_evento[] - Array das últimas medidas existentes no banco para
  #                             fins de comparação com as medidas que estão chegando
  #                             do web service.
  #
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

          if ultima
            gauge = ultima_medida.gauge.present? ? ultima_medida.gauge : 'analogico'
              if ultima_medida.reporte_medida_id.present?
                reporte_medida_id = ultima_medida.reporte_medida_id
              elsif codigo_by_equipamento.codigo.id == TEMPERATURA_DEFAULT
                reporte_medida_id = REPORTE_TEMPERATURA
              elsif codigo_by_equipamento.codigo.id >= INICIO_DIGITAIS
                reporte_medida_id = REPORTE_ENERGIA
              else
                reporte_medida_id = REPORTE_FAIXA
              end
          else
            if codigo_by_equipamento.codigo.id == TEMPERATURA_DEFAULT
              gauge = 'temperatura'
              reporte_medida_id = REPORTE_TEMPERATURA
            elsif codigo_by_equipamento.codigo.id >= INICIO_DIGITAIS
              reporte_medida_id = REPORTE_ENERGIA
              gauge = 'led'
            elsif (codigo_by_equipamento.codigo.id >= INICIO_NEGATIVAS and codigo_by_equipamento.codigo.id < FIM_NEGATIVAS)
              reporte_medida_id = REPORTE_FAIXA
              gauge = 'digital'
            else
              gauge = 'analogico'
              reporte_medida_id = REPORTE_FAIXA
            end
          end

          medida.equipamento_id       = equipamento.id
          medida.indice               = ultima ? ultima_medida.indice : medida.indice = indice
          medida.disponivel_ambiente  = codigo_by_equipamento.disponivel_ambiente
          medida.nome                 = ultima ? ultima_medida.nome : codigo_by_equipamento.codigo.codigo
          medida.unidade_medida       = ultima ? ultima_medida.unidade_medida : nil
          medida.reporte_medida_id = reporte_medida_id.to_i
          medida.gauge                = gauge
          medida.temperatura_ambiente = codigo_by_equipamento.disponivel_temperatura
          medida.grandeza             = ultima ? ultima_medida.grandeza.present? ? ultima_medida.grandeza : '' : ''
          medida.divisor              = ultima ? ultima_medida.divisor.present? ? ultima_medida.divisor : 0 : 0
          medida.multiplo             = ultima ? ultima_medida.multiplo.present? ? ultima_medida.multiplo : 0 : 0
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

  # Internal - Pega a última faixa laranja de uma medida
  #
  def self.take_last_orange_track ultima_medida
    ultima_medida ? (ultimas_faixas = Medida::busca_faixas_medida ultima_medida.id) : ultimas_faixas = []
    ultima_faixa = ultimas_faixas.second
  end

  # Internal - verifica se a media de configuração que esta tentando ser persistida
  #            possui algum dado novo ou é igual a ultima enviada se retornar true
  #            é uma sinalização de que a faixa tem novos dados, se não ele é igual
  #            a última.
  #
  # ultima_faixa: contem apenas a faixa verde, por que o pacote de configuração
  #               envia apenas esta
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

  # Internal - busca as faixas de uma medida através do medida_id
  #
  # Retorna as três faixas de uma medida
  def self.busca_faixas_medida medida_id
    faixas = Faixa.where(medida_id: medida_id).order(:status_faixa)
  end

  # Internal - Verifica se uma medida é Digital (D1 até D4), porque a forma de
  #            tratar as medidas digitais e diferente:
  #            Forma: valor mínio da faixa é um número escolhido pelo usuário e o
  #            valor máximo é o número escolhido pelo usuário mais 1
  #            caso a medida não seja do tipo digital.
  #            O sistema pega as faixas "verde" e "laranja", que vem da telemetria
  #            juntas e de acordo com as informações do seu banco de dados recria
  #            as faixas "verde" e "laranja"
  #
  def self.persiste_faixas medida, faixa, ultima_medida
    ultima_medida ? (ultimas_faixas = Medida::busca_faixas_medida ultima_medida.id) : ultimas_faixas = []

    if medida.id_local >= INICIO_DIGITAIS and medida.id_local <= FIM_DIGITAIS
      Faixa.create(medida_id: medida.id, status_faixa: OK, disable: false, minimo: faixa[:normal], maximo: faixa[:normal].to_i + 0.99 )
      Faixa.create(medida_id: medida.id, status_faixa: ALERTA, disable: false, minimo: 50, maximo: 51 )
      normal = faixa[:normal].to_i == 0 ? 1 : 0
      Faixa.create(medida_id: medida.id, status_faixa: ALARME, disable: false, minimo: normal, maximo: normal.to_i + 0.99 )
    else
      green_track, orange_track = track_divisor ultima_medida, medida, faixa

      Faixa.create(medida_id: medida.id, status_faixa: OK, disable: false, minimo: green_track[:minimo], maximo: green_track[:maximo] )

      if orange_track
        Faixa.create(medida_id: medida.id, status_faixa: ALERTA, disable: false, minimo: orange_track[:minimo], maximo: orange_track[:maximo] )
      else
        Faixa.create(medida_id: medida.id, status_faixa: ALERTA, disable: false, minimo: 0, maximo: 0)
      end

    end
  end


  # Internal - De acordo com as informações das faixas presentes no banco de dados
  #            e as fornecidas pelo web_service ao receber o pacote de configuração
  #            de uma telemetria realiza a divisão das faixas "verde" e "laranja"
  #
  def self.track_divisor ultima_medida, medida, faixa
    if ultima_medida
      last_orange_track = take_last_orange_track ultima_medida

      # p "minimo laranja : #{last_orange_track.minimo} | maximo laranja : #{last_orange_track.maximo}"
      # p "minimo verde : #{faixa[:minimo]} | maximo verde : #{faixa[:maximo]}"

      last_orange_track = readjustment_orange_track last_orange_track, faixa

      if last_orange_track

        # caso o laranja esteja no meio do verde, eu transformo o primeiro verde
        # em laranja,
        if (faixa[:maximo].to_i > last_orange_track[:maximo].to_i) and (faixa[:minimo].to_i < last_orange_track[:minimo].to_i)
          last_orange_track[:minimo] = faixa[:minimo]
        end

        # caso o verde esteja no meio do laranja o primeiro laranja
        # é transformado em verde
        if ((last_orange_track[:maximo].to_i > faixa[:maximo].to_i) and (last_orange_track[:minimo].to_i < faixa[:minimo].to_i))
          faixa[:minimo] = last_orange_track[:minimo] + 1
        end

          if faixa[:maximo].to_i > last_orange_track[:maximo].to_i
            minimo = last_orange_track[:maximo].to_i
            minimo = minimo + 1
            maximo = faixa[:maximo]
          else
            maximo = last_orange_track[:minimo].to_i
            maximo = maximo - 1
            minimo = faixa[:minimo]
          end

      else
        return faixa, false
      end

       green_track = {:minimo=> minimo, :maximo=> maximo, :timer=> medida.timer.to_s}
       last_orange_track
      return green_track, last_orange_track
    else
      return faixa, false
    end
  end

  # Internal - Reajusta a faixa laranja, quando a versão do web da mesma apresenta
  #            diferenças quando ao pacote recebido pela telemetria, tal anomalia
  #            pode acontecer quando existir falha de comunicação do web com a
  #            telemetria
  def self.readjustment_orange_track orange_track, green_track
    invalid_orange = false

    if ((orange_track.minimo.to_i == green_track[:minimo].to_i) and (orange_track.maximo.to_i == green_track[:maximo].to_i))
      invalid_orange = true

    elsif ((orange_track.minimo.to_i < green_track[:minimo].to_i) and (orange_track.maximo.to_i < green_track[:minimo].to_i))
      invalid_orange = true

    elsif ((orange_track.maximo.to_i > green_track[:maximo].to_i) and (orange_track.minimo.to_i > green_track[:maximo].to_i))
        invalid_orange = true

    elsif ((orange_track.minimo.to_i < green_track[:minimo].to_i) and (orange_track.maximo.to_i < green_track[:maximo].to_i))
        minimo = green_track[:minimo].to_i
        maximo = orange_track.maximo.to_i

    elsif ((orange_track.maximo.to_i > green_track[:maximo].to_i) and (orange_track.minimo.to_i > green_track[:maximo].to_i))
      minimo = orange_track.minimo.to_i
      maximo = green_track[:maximo]

    elsif ((orange_track.maximo.to_i > green_track[:maximo].to_i) and (orange_track.minimo.to_i < green_track[:minimo].to_i))
      minimo = green_track[:minimo] +2
      maximo = green_track[:maximo]

    elsif ((orange_track.minimo.to_i > green_track[:minimo].to_i) and (orange_track.maximo.to_i > green_track[:maximo].to_i))
      minimo = orange_track.minimo.to_i
      maximo = green_track[:maximo]

    else
      minimo = orange_track.minimo.to_i
      maximo = orange_track.maximo.to_i
    end

    if invalid_orange
      orange_track = false
    else
      orange_track = {:minimo=> minimo, :maximo=> maximo}
    end
  end

  # Internal - Seleciona todas as meddias ambiente dos equipamentos passados pelo
  #            parâmetro, caso a medida ambiente for repetida, seleciona apenas
  #            que tiver oo maior ID.
  #
  # Retorna as medidas ambientes já unificadas pelo maior ID.
  def self.last_environment_measures equipamentos
    medidas_ids = Medida.select('MAX(id) id, id_local').where(equipamento_id: equipamentos).where(id_local: [D1,D2,D3,D4]).group(:id_local).map(&:id)
    medidas = Medida.where(id: medidas_ids)
    medidas = medidas.uniq { |medida| medida.id_local}
  end

end
