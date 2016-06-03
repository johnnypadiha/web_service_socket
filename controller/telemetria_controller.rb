class TelemetriaController
  def self.find_telemetria(params)
    return Telemetria.find_by_codigo(params[:codigo].to_i)
  end

  def self.atualiza_telemetria(telemetria, params)
    telemetria.updated_at = params[:data]
    telemetria.nivel_sinal = params[:nivel_sinal]
    if telemetria.save
      return true 
    else
      return false
    end
  end
end
