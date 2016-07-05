class TelemetriaController
  def self.find_telemetria(params)
    return Telemetria.find_by_codigo(params[:codigo].to_i)
  end

  def self.atualiza_telemetria(telemetria, params)
    unless params.blank?
      telemetria.updated_at               = params[:data] unless params[:data].blank?
      telemetria.nivel_sinal              = params[:nivel_sinal] unless params[:nivel_sinal].blank?
      telemetria.firmware                 = params[:firmware] unless params[:firmware].blank?
      telemetria.ip_server_primario       = params[:ip_primario] unless params[:ip_primario].blank?
      telemetria.ip_server_secundario     = params[:ip_secundario] unless params[:ip_secundario].blank?
      telemetria.porta_server_primario    = params[:porta_ip_primario] unless params[:porta_ip_primario].blank?
      telemetria.porta_server_secundario  = params[:porta_ip_secundario] unless params[:porta_ip_secundario].blank?
      telemetria.operadora                = params[:operadora] unless params[:operadora].blank?
      telemetria.host_server              = params[:host] unless params[:host].blank?
      telemetria.porta_host               = params[:porta_dns] unless params[:porta_dns].blank?
      telemetria.periodico                = params[:timer_periodico] unless params[:timer_periodico].blank?

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
