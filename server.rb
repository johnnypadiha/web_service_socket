include Logging
class WebService
require 'active_support/time'

  def initialize(ip, porta)
    api(ip,porta)
  end

  def api(ip,porta)
    logger.info("RUN API --------------------")
    EventMachine.run {
      timer = EventMachine::PeriodicTimer.new(180) do
        index = []
        index = $lista_telemetria.map.with_index{|v, i| i if v[:hora].to_time < 5.minutes.ago}.compact

        unless index.nil?
          index.reverse_each do |i|
            $lista_telemetria[i][:socket].close_connection
            logger_connection.info("telemetria ausente ID : #{$lista_telemetria[i][:id]} - Desconectada!")
            $lista_telemetria.delete_at(i)
          end
        end

        logger_connection.info "---- LISTA DE TELEMETRIAS CONECTADAS ----"
        $lista_telemetria.each do |t|
          logger_connection.info "ID : #{t[:id]} - IP #{t[:ip]} - Hora da Conexão #{t[:hora]}"
        end
        logger_connection.info "-----------------------------------------"
      end
      EventMachine.start_server ip, porta, AnalogicProcess
    }
  end
end
