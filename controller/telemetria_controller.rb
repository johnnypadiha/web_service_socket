class TelemetriaController

  # Internal : Busca todos os dados da Telemetria pelo código da mesma
  #
  # params - Hash contendo os dados da Telemetria que enviou o pacote.
  # params[:codigo_telemetria] - Integer contendo o código da Telemetria a ter
  #             seus dados buscados
  # return - Objeto contendo uma Telemetria
  def self.find_telemetria(params)
    return Telemetria.find_by_codigo(params[:codigo_telemetria].to_i)
  end

  # Internal : Busca o código da Telemetria afim de validar se essa é válida e
  #             cadastrada.
  #
  # codigo - Integer contendo o código da Telemetria passado como parâmetro.
  # return - Retorna o código da Telemetria caso encontrado
  def self.find_by_codigo(codigo)
    return Telemetria.select(:codigo, :id).find_by_codigo(codigo.to_i)
  end

  # Internal : Verifica se o código da telemetria recebido no pacote está cadastrado
  #             como uma Telemetria.
  #
  # pacote - Parâmetro contendo o pacote recebido da Telemetria
  # return Boolean
  def self.verifica_telemetria pacote, ip
    codigo = ProcessarPacotes::obtem_codigo_telemetria(pacote)
    telemetria = TelemetriaController.find_by_codigo(codigo)

    telemetria_existe =
      if telemetria.present?
        telemetria.update(ip: ip)
        true
      else
        false
      end
    return telemetria_existe, codigo
  end

  # Internal : Atualiza registro de uma Telemetria
  #
  # telemetria - Objeto contendo uma Telemetria
  # params - Hash contendo dados de uma Telemetria para sofrer atualizações no
  #           registro.
  # return Boolean
  def self.atualiza_telemetria(telemetria, params)
    if params.present? && telemetria.present?
      telemetria.updated_at               = params[:data] unless params[:data].blank?
      telemetria.firmware                 = params[:firmware] unless params[:firmware].blank?
      telemetria.ip_server_primario       = params[:ip_primario] unless params[:ip_primario].blank?
      telemetria.ip_server_secundario     = params[:ip_secundario] unless params[:ip_secundario].blank?
      telemetria.porta_server_primario    = params[:porta_ip_primario] unless params[:porta_ip_primario].blank?
      telemetria.porta_server_secundario  = params[:porta_ip_secundario] unless params[:porta_ip_secundario].blank?
      telemetria.operadora                = params[:operadora] unless params[:operadora].blank?
      # telemetria.host_server              = params[:host] unless params[:host].blank?
      telemetria.porta_host               = params[:porta_dns] unless params[:porta_dns].blank?
      telemetria.periodico                = params[:timer_periodico].to_i * 60 unless params[:timer_periodico].blank?

      if telemetria.save
        return true, telemetria.id
      else
        return false
      end
    else
      return false
    end
  end
end
