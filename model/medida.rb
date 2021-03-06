class Medida < ActiveRecord::Base
  self.table_name = 'main.medidas'

  belongs_to :equipamento
  has_many :medidas_eventos
  has_many :faixas

  # Internal: Recebe o ID da telemetria e os dados provenientes do pacote da
  #           telemetria, compara com a ultima faixa do banco de dados e/ou
  #           com as faixas da tabela de saida e chama os metodos que realizam
  #           a persistencia das faixas e das medidas, apos este chama o metodo
  #           que persiste o evento de configuracao.
  #
  #   id_telemetria - Integer que armazena o id da telemetria no banco de dados
  #   analogicas, negativas e digitais - Hash que armazena os valores minimo,
  #   maximo e timer de cada medida vinda do pacote de configuracao.
  #   @mudanca_faixa - Boolean para identificar se ocorreu mudanca na faixa
  #   @aguardando_configuracao - Boolean que identifica que existe alguma saida
  #                              na tabela de saida aguardando a chegada de uma
  #                              configuracao
  #   @first_configuration - Boolean que determina se e a primeira vez que a
  #                         medida esta sendo persistida.
  #   @medidas[] - Array de objetos Medidas e Faixas
  #   @medidas_evento[] - Array de medidas que irao compor o evento de
  #                      configuracao
  #   @ultimas_medidas_evento[] - Array das ultimas medidas que tambem podem
  #                             compor o evento de configuracao
  #   indice - Integer que armazena o indice que ira ordenar as medidas na tela
  #   medidas - unizao dos Hashs (analogicas, digitais e negativas)
  #   parameters - parametros para geracao do objeto Medida
  #
  def self.create_medidas(id_telemetria, analogicas, negativas, digitais)
    Medida.reset_instant_read_complete id_telemetria, [RESET_TELEMETRY,
                                                       INSTANT_READING]
    equipamentos = Equipamento.where(telemetria_id: id_telemetria)
    if equipamentos.blank?
      Logging.warn "Nenhum equipamento cadastrado para Telemetria
      ID: #{id_telemetria}"
    else
      equipamentos_evento = []
      @mudanca_faixa = false
      @mudanca_ambiente = false
      @aguardando_configuracao = false
      @first_configuration = false
      @medidas = []
      @medidas_evento = []
      @ultimas_medidas_evento = []
      medidas = {}
      equipamentos.each do |equipamento|
        equipamento.process_saida_virtual
        codigos_by_equipamento =
          EquipamentosCodigo.where(equipamento_id: equipamento.id)
                            .includes(:codigo)
        codigos_by_equipamento.each do |codigo_by_equipamento|
          equipamentos_evento.push(codigo_by_equipamento.equipamento_id)
          medida = Medida.new
          medidas = analogicas.merge(negativas)
          medidas = medidas.merge(digitais)
          @faixa = Medida.tracks_extractor medidas, codigo_by_equipamento
          ultima_medida =
            Medida.where(equipamento_id: equipamento,
                         id_local: codigo_by_equipamento.codigo.id).last
          indice = codigo_by_equipamento.codigo.id
          indice -= 1
          gauge, reporte_medida_id =
            Medida.gauge_config_save ultima_medida, codigo_by_equipamento

          parameters = { medida: medida, equipamento_id: equipamento.id,
                         indice: indice,
                         codigo_by_equipamento: codigo_by_equipamento,
                         ultima_medida: ultima_medida,
                         reporte_medida_id: reporte_medida_id, gauge: gauge,
                         timer: @faixa[:timer] }

          medida = Medida.popula_measure parameters

          if ultima_medida
            if Medida.faixas_medidas_mudaram ultima_medida, medida, @faixa
              @mudanca_faixa = true
            end

            if Medida.mudanca_ambiente ultima_medida, medida
              @mudanca_ambiente = true
            end
            saida_present =
              Saida.where(aguardando_configuracao: true,
                             id_local: ultima_medida.id_local,
                             telemetria_id: id_telemetria).first
            if saida_present.present?
              @aguardando_configuracao = true
              @mudanca_faixa = false
              @saida_id = saida_present.id
            end
            if @mudanca_faixa || @aguardando_configuracao || @mudanca_ambiente
              @medidas_evento << medida
            else
              @medidas_evento << ultima_medida
            end
            @first_configuration = false
          else
            @medidas_evento << medida
            @first_configuration = true
          end

          @ultimas_medidas_evento << ultima_medida
          @medidas_faixas = { medida: medida,
                              faixa: @faixa,
                              ultima_medida: ultima_medida,
                              aguardando_configuracao: @aguardando_configuracao,
                              saida_id: @saida_id || nil,
                              mudanca_faixa: @mudanca_faixa,
                              mudanca_ambiente: @mudanca_ambiente,
                              first_configuration: @first_configuration }
          @medidas << @medidas_faixas
          @mudanca_faixa = false
          @aguardando_configuracao = false
          @first_configuration = false
        end
      end

      Medida.save_tracks_and_measures @medidas

      equipamentos_evento = equipamentos_evento.uniq
      if equipamentos_evento.present?
        Evento.persiste_evento_configuracao equipamentos_evento, @medidas_evento
      else
        Logging.warn "É necessário cadastrar um equipamento e/ou pelo menos uma
        medida para que o evento de configuração seja persistido.
        Telemetria ID: #{id_telemetria}"
        return false
      end
    end
  end

  # Internal: quando receber um pacote de configuracao, marcar reset telemetria
  #           e leitura instantanea como concluidas, se existirem as mesmas na
  #           tabela de saida
  #
  def self.reset_instant_read_complete(id_telemetria, commands)
    outings = Saida.where("comando IN (?) and processado = ? and
    telemetria_id = ?", commands, false, id_telemetria)
    outings.each do |out|
      out.processado = true
      out.data_processamento = Time.now
      out.cancelado = false
      out.save
    end
  end

  # Internal: Recebe um Hash com todas as informacoes de uma medida e escolhe a
  #           forma como devera ser persistido as faixas e a medida
  #
  #   medidas - Hash com o objeto Medida populado, porem nao persistido.
  #   medida[:faixa].dup - cria um novo objeto a partir de uma copia do objeto
  #
  def self.save_tracks_and_measures medidas
    medidas.each do |medida|
      if medida[:medida].id_local >= INICIO_DIGITAIS &&
         medida[:medida].id_local <= FIM_DIGITAIS
        if medida[:aguardando_configuracao]
          saidas = Saida.where("aguardando_configuracao = ?
          and id_local > ?
          and telemetria_id = ?", true, 20,
          medida[:ultima_medida].equipamento.telemetria_id)
          saidas.update_all(aguardando_configuracao: false)
          Medida.create_measures_tracks(medida[:medida], medida[:faixa], true)
        elsif Medida.faixas_medidas_mudaram medida[:ultima_medida],
                                            medida[:medida],
                                            medida[:faixa].dup
        Medida.create_measures_tracks(medida[:medida], medida[:faixa], true)
        elsif medida[:mudanca_ambiente]
          Medida.create_measures_tracks(medida[:medida], medida[:faixa], true)
        end
      elsif medida[:first_configuration]
        Logging.info "primeira configuracao da medida"
        green_track, orange_track = blood_force_track_create medida[:faixa]
        faixa_saida = SaidaFaixas.new
        faixa_saida.minimo = green_track[:minimo]
        faixa_saida.maximo = green_track[:maximo]
        faixa_saida.minimo_laranja = orange_track[:minimo]
        faixa_saida.maximo_laranja = orange_track[:maximo]
        Medida.create_measures_tracks(medida[:medida], faixa_saida, false)
      elsif medida[:aguardando_configuracao]
        Logging.info "mudanca de faixa aguardando_configuracao da tabela de
                      saida"
        Medida.persiste_faixas_saida medida[:medida],
                                     medida[:faixa].dup,
                                     medida[:ultima_medida],
                                     medida[:saida_id]

      elsif medida[:mudanca_faixa] || medida[:mudanca_ambiente]
        Logging.info "ocorreu mudanca de faixa nao prevista na tabela de saida"
        medida[:medida].save
        Medida.persiste_faixas medida[:medida],
                               medida[:faixa].dup,
                               medida[:ultima_medida]
      end
    end
  end

  # Internal - popula os campos do objeto Medida com os valores provenientes da
  #            telemetria, do software web ou valores defaults da medida
  #
  #   parameters - parametros para geracao do objeto Medida
  #
  def self.popula_measure(parameters)
    parameters[:medida].equipamento_id =
      parameters[:equipamento_id]
    parameters[:medida].disponivel_ambiente =
      parameters[:codigo_by_equipamento].disponivel_ambiente
    parameters[:medida].reporte_medida_id =
      parameters[:reporte_medida_id].to_i
    parameters[:medida].gauge =
      parameters[:gauge]
    parameters[:medida].temperatura_ambiente =
      parameters[:codigo_by_equipamento].disponivel_temperatura
    parameters[:medida].id_local =
      parameters[:codigo_by_equipamento].codigo.id
    parameters[:medida].timer =
      parameters[:timer]
    if parameters[:ultima_medida].present?
      parameters[:medida].indice =
        parameters[:ultima_medida].indice
      parameters[:medida].nome =
        parameters[:ultima_medida].nome
      parameters[:medida].unidade_medida =
        parameters[:ultima_medida].unidade_medida
      parameters[:medida].grandeza =
        parameters[:ultima_medida].grandeza
      parameters[:medida].divisor =
        parameters[:ultima_medida].divisor
      parameters[:medida].multiplo =
        parameters[:ultima_medida].multiplo
    elsif parameters[:codigo_by_equipamento].disponivel_temperatura
      parameters[:medida].nome = 'Temperatura Ambiente'
      parameters[:medida].grandeza = 'ºC'
      parameters[:medida].indice =
        parameters[:indice]
    else
      parameters[:medida].indice =
        parameters[:indice]
      parameters[:medida].nome =
        parameters[:codigo_by_equipamento].codigo.codigo
      parameters[:medida].unidade_medida = nil
      parameters[:medida].grandeza = ''
      parameters[:medida].divisor = 0
      parameters[:medida].multiplo = 0
    end
    return parameters[:medida]
  end

  # Internal - Compara se a medida proveniente do pacote, pertence ao
  #            codigo por equipamento passado como parametro, se sim retorna as
  #            faixas e o timer
  #
  def self.tracks_extractor(medidas, codigo_by_equipamento)
    medidas.each do |k, v|
      if k.to_s == codigo_by_equipamento.codigo.codigo.to_s
        return faixas = v
      end
    end
  end

  # Internal: Seta as configuracoes do gauge, reporte e tipo, de acordo com as
  #            configuracoes escolhidas anteriormente ou o default de cada gauge
  #
  # last_measure - Objeto medida com os valores da ultima medida da medida em
  #                questao
  # codigo_by_equipamento - Lista de codigos, provenientes da tabela
  #                         equipamentos_codigos
  #
  # Returns uma String com o tipo de gauge escolhido e o ID do reporte da medida
  def self.gauge_config_save(last_measure, codigo_by_equipamento)
    if last_measure.present?
      gauge = last_measure.gauge.present? ? last_measure.gauge : 'analogico'
      reporte_medida_id =
        if last_measure.reporte_medida_id.present?
          last_measure.reporte_medida_id
        elsif codigo_by_equipamento.codigo.id == TEMPERATURA_DEFAULT
          REPORTE_TEMPERATURA
        elsif codigo_by_equipamento.codigo.id >= INICIO_DIGITAIS
          REPORTE_ENERGIA
        else
          REPORTE_FAIXA
        end
    else
      if codigo_by_equipamento.codigo.id == TEMPERATURA_DEFAULT
        gauge = 'temperatura'
        reporte_medida_id = REPORTE_TEMPERATURA
      elsif codigo_by_equipamento.codigo.id >= INICIO_DIGITAIS
        reporte_medida_id = REPORTE_ENERGIA
        gauge = 'led'
      elsif codigo_by_equipamento.codigo.id >= INICIO_NEGATIVAS &&
            codigo_by_equipamento.codigo.id < FIM_NEGATIVAS
        reporte_medida_id = REPORTE_FAIXA
        gauge = 'digital'
      else
        gauge = 'analogico'
        reporte_medida_id = REPORTE_FAIXA
      end
    end
    return gauge, reporte_medida_id
  end

  # Internal - Verifica se os valores da tabela de saida estao condizentes com
  #            os valores que vieram da configuracao vinda da telemetria, se sim
  #            chama a o metodo que realiza a persistencia das medidas e faixas
  #            se nao, forca a divisao da faixa verde em (metade verde, metade
  #            laranja) e realiza a persistencia, em ambos os casos marca a
  #            "aguardando_configuracao" da tabela de saida como concluido.
  #
  #   Medida - Objeto medida atual em questao
  #   ultima_medida - Objeto medida da ultima medida em questao
  #   faixa - Hash com o minimo, maximo e timer da medida proveniente do pacote
  #
  def self.persiste_faixas_saida medida, faixa, ultima_medida, saida_id
    orange_track = {}
    saida = Saida.find(saida_id)
    faixa_saida = SaidaFaixas.find_by_saida_id(saida.id)
    unify_track = Medida.unify_tracks faixa_saida
    if unify_track[:green_max].to_f == faixa[:maximo].to_f &&
       unify_track[:green_min].to_f == faixa[:minimo].to_f
      orange_track[:minimo] = faixa_saida.minimo_laranja
      orange_track[:maximo] = faixa_saida.maximo_laranja
      green_track, orange_track = Medida.create_orange_and_green_tracks orange_track, faixa
      faixa_saida.minimo = green_track[:minimo]
      faixa_saida.maximo = green_track[:maximo]
      faixa_saida.minimo_laranja = orange_track[:minimo]
      faixa_saida.maximo_laranja = orange_track[:maximo]
    else
      green_track, orange_track = Medida.blood_force_track_create faixa
      faixa_saida.minimo = green_track[:minimo]
      faixa_saida.maximo = green_track[:maximo]
      faixa_saida.minimo_laranja = orange_track[:minimo]
      faixa_saida.maximo_laranja = orange_track[:maximo]
    end
    Medida.create_measures_tracks medida, faixa_saida, false
    saida.aguardando_configuracao = false
    saida.save
  end

  # Internal - Realiza a divisao de faixas entre "verde" e "laranja", utilizando
  #            como referencia a faixa vinda da telemetria e a faixa presente no
  #            banco de dados "verde", descobre se a faixa laranja esta no
  #            inicio ou no final do pacote vindo da telemetria
  #
  def self.create_orange_and_green_tracks(orange_track, green_track)
    if orange_track[:minimo] == green_track[:minimo]
      green_track[:minimo] = orange_track[:maximo] + 0.1
    else
      green_track[:maximo] = orange_track[:minimo] - 0.1
    end
    return green_track, orange_track
  end

  # Internal - persiste medidas e faixas
  #
  # digital - true para D1 ate D4 e false para as outras medidas
  #
  def self.create_measures_tracks(medida, faixa_saida, digital)
    medida.save
    if digital
      Faixa.create(medida_id: medida.id,
                   status_faixa: OK,
                   disable: false,
                   minimo: faixa_saida[:normal],
                   maximo: faixa_saida[:normal].to_i + 0.99)
      Faixa.create(medida_id: medida.id,
                   status_faixa: ALERTA,
                   disable: false,
                   minimo: 50,
                   maximo: 51)
      normal = faixa_saida[:normal].to_i.zero? ? 1 : 0
      Faixa.create(medida_id: medida.id,
                   status_faixa: ALARME,
                   disable: false,
                   minimo: normal,
                   maximo: normal.to_i + 0.99)
    else
      Faixa.create(medida_id: medida.id,
                   status_faixa: OK,
                   disable: false,
                   minimo: faixa_saida.minimo,
                   maximo: faixa_saida.maximo)
      Faixa.create(medida_id: medida.id,
                   status_faixa: ALERTA,
                   disable: false,
                   minimo: faixa_saida.minimo_laranja,
                   maximo: faixa_saida.maximo_laranja)
    end
  end

  # Internal - Verifica se uma medida e Digital (D1 ate D4), porque a forma de
  #            tratar as medidas digitais e diferente:
  #            Forma: valor minio da faixa e um numero escolhido pelo usuario e
  #            o valor maximo e o numero escolhido pelo usuario mais 1 caso a
  #            medida nao seja do tipo digital, o sistema pega as faixas "verde"
  #            e "laranja", que vem da telemetria juntas e de acordo com as
  #            informacoes do seu banco de dados recria as faixas "verde" e
  #            "laranja"
  #
  def self.persiste_faixas medida, faixa, ultima_medida
    ultima_medida ? (ultimas_faixas = Medida::busca_faixas_medida ultima_medida.id) : ultimas_faixas = []

    if medida.id_local >= INICIO_DIGITAIS and medida.id_local <= FIM_DIGITAIS
      Faixa.create(medida_id: medida.id, status_faixa: OK, disable: false, minimo: faixa[:normal], maximo: faixa[:normal].to_i + 0.99 )
      Faixa.create(medida_id: medida.id, status_faixa: ALERTA, disable: false, minimo: 50, maximo: 51 )
      normal = faixa[:normal].to_i == 0 ? 1 : 0
      Faixa.create(medida_id: medida.id, status_faixa: ALARME, disable: false, minimo: normal, maximo: normal.to_i + 0.99 )
    else

      if ultima_medida
        green_track, orange_track = track_divisor ultima_medida, faixa
        Faixa.create(medida_id: medida.id, status_faixa: OK, disable: false, minimo: green_track[:minimo], maximo: green_track[:maximo])
        Faixa.create(medida_id: medida.id, status_faixa: ALERTA, disable: false, minimo: orange_track[:minimo], maximo: orange_track[:maximo])
      else
        Faixa.create(medida_id: medida.id, status_faixa: OK, disable: false, minimo: faixa[:minimo], maximo: faixa[:maximo].to_i > 0 ? faixa[:maximo]-1 : faixa[:maximo])
        Faixa.create(medida_id: medida.id, status_faixa: ALERTA, disable: false, minimo: faixa[:maximo], maximo: faixa[:maximo])
      end
    end
  end

  # Internal - Unifica as faixas verdes e laranja para que fiquem como sao na
  #            Telemetria
  #
  def self.unify_tracks(faixas)
    unify_track = { green_min: nil, green_max: nil }
    faixas.minimo = faixas.minimo_laranja if faixas.minimo == nil
    faixas.maximo = faixas.maximo_laranja if faixas.maximo == nil
    faixas.minimo_laranja = faixas.minimo if faixas.minimo_laranja == nil
    faixas.maximo_laranja = faixas.maximo if faixas.maximo_laranja == nil

    if faixas.minimo < faixas.minimo_laranja
      unify_track[:green_max] = faixas.maximo_laranja
      unify_track[:green_min] = faixas.minimo
    else
      unify_track[:green_max] = faixas.maximo
      unify_track[:green_min] = faixas.minimo_laranja
    end
    unify_track
  end



  # Internal - Pega a ultima faixa de uma medida
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
    ultima_medida ? (ultimas_faixas = Medida.busca_faixas_medida ultima_medida.id) : ultimas_faixas = []
    ultima_faixa = ultimas_faixas.first
    ultima_faixa_laranja = ultimas_faixas.second

    if ultima_faixa.present?
      if medida.id_local >= INICIO_DIGITAIS && medida.id_local <= FIM_DIGITAIS
        if (ultima_faixa.minimo.to_f == faixa[:normal].to_f) &&
           (ultima_faixa.maximo.to_f == faixa[:normal].to_i.to_f + 0.99) &&
           (timer == ultima_medida.timer)
          return false
        else
          return true
        end
      else
        saida_faixas = SaidaFaixas.new
        saida_faixas.minimo = ultima_faixa.minimo
        saida_faixas.maximo = ultima_faixa.maximo
        saida_faixas.minimo_laranja = ultima_faixa_laranja.minimo
        saida_faixas.maximo_laranja = ultima_faixa_laranja.maximo
        unify_track = Medida.unify_tracks saida_faixas
        if (unify_track[:green_min].to_f == faixa[:minimo].to_f) &&
           (unify_track[:green_max].to_f == faixa[:maximo].to_f) &&
           (timer == ultima_medida.timer)
          return false
        else
          return true
        end
      end
    else
      return true
    end
  end

  # Internal - verifica se ocorreu mudanca em medidas que eram do ambiente e
  # agora nao mais pertencema ao mesmo e vice-versa
  #
  def self.mudanca_ambiente ultima_medida, medida
    if ultima_medida.disponivel_ambiente != medida.disponivel_ambiente ||
       ultima_medida.temperatura_ambiente != medida.temperatura_ambiente
      return true
    else
      return false
    end
  end

  # Internal - busca as faixas de uma medida através do medida_id
  #
  def self.busca_faixas_medida medida_id
    faixas = Faixa.where(medida_id: medida_id).order(:status_faixa)
  end



  # Internal - De acordo com as informações das faixas presentes no banco de dados
  #            e as fornecidas pelo web_service ao receber o pacote de configuração
  #            de uma telemetria realiza a divisão das faixas "verde" e "laranja",
  #            caso o pacote recebido da telemetria apresente inconsistência em
  #            relação a faixa laranja já salva no web, envia para o método que
  #            vai forçar a adequação da mesma
  #
  # incompatible: flag que determina se a faixa que veio da telemetria e a faixa
  #               laranja presente no servidor são compatíveis, caso não sejam essa
  #               variável recebe TRUE
  #
  def self.track_divisor last_measure, green_track
    last_orange_track = take_last_orange_track last_measure
    incompatible = false

    orange_track = { minimo: last_orange_track.minimo.to_f, maximo: last_orange_track.maximo.to_f }
    green_track = {minimo: green_track[:minimo].to_f, maximo: green_track[:maximo].to_f}

    #laranja saindo fora do verde
    if orange_track[:maximo] > green_track[:maximo] or orange_track[:minimo] < green_track[:minimo]
      incompatible = true
    #laranja distante do verde
    elsif orange_track[:maximo] < green_track[:minimo] or orange_track[:minimo] > green_track[:maximo]
      incompatible = true
    #sobrando 2 verdes no laranja
    elsif green_track[:maximo] > orange_track[:maximo] and green_track[:minimo] < orange_track[:minimo]
      incompatible = true
    #o laranja é igual o verde
    elsif green_track[:maximo] == orange_track[:maximo] and green_track[:minimo] == orange_track[:minimo]
      incompatible = true
    else
      incompatible = false
    end

    if incompatible
      green_track, orange_track = blood_force_track_create green_track
    else
      green_track, orange_track = create_orange_and_green_tracks orange_track, green_track
    end

    return green_track, orange_track
  end

  # Internal - Forca a criacao das faixas "verde" e "laranja" seguindo a logica
  #            da divisao do pacote que chegou da telemetria em 50% para cada
  #            cor exceto quando a faixa vinda da telemetria e muito pequena e
  #            nao pode ser dividida meio a meio, na primeira configuracao da
  #            telemetria em que a faixa verde vem de 100 ate 100 o sistema
  #            divide o 100.0 ate o 100.99 entre verde e laranja
  #
  def self.blood_force_track_create green_track
    orange_track = { minimo: nil, maximo: nil }
    middle = Medida.take_middle green_track
    if green_track[:maximo] == 100 && green_track[:minimo] == 100
      green_track[:minimo] = 100
      green_track[:maximo] = 100.5
      orange_track[:minimo] = 100.6
      orange_track[:maximo] = 100.9
    else
      if green_track[:maximo] - green_track[:minimo] > 3
        orange_track[:minimo] = green_track[:minimo]
        orange_track[:maximo] = middle - 0.1
        green_track[:minimo] = middle
      else
        if green_track[:maximo] - green_track[:minimo] <= 3
          orange_track[:minimo] = middle + 0.1
          orange_track[:maximo] = green_track[:maximo]
          green_track[:maximo] = middle
        else
          orange_track[:minimo] = green_track[:minimo]
          orange_track[:maximo] = green_track[:minimo]
          green_track[:minimo] = green_track[:minimo] + 0.5
        end
      end
    end
    return green_track, orange_track
  end

# Internal: recebe a faixa primaria da telemetria e retorna o valor que fica
#           exatamente no meio dessa faixa
#
def self.take_middle track
  ((track[:maximo] - track[:minimo]) / 2) + track[:minimo]
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
