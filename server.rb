include Logging
class WebService
require 'active_support/time'

  def initialize(ip, porta)
    api(ip,porta)
  end

  def api(ip,porta)
    logger.info("RUN API --------------------")
    EventMachine.run {
      EventMachine.error_handler do |e|
        logger.info "Exception during event: #{e.message} (#{e.class})".red
        logger.info (e.backtrace || [])[0..10].join("\n")
      end

      EventMachine::PeriodicTimer.new(120) do
        logger_connection.info("Total de sockets conectados : #{$sockets_conectados.size}")
        logger_connection.info("Total de telemetrias conectadas : #{$lista_telemetria.size}")
        logger_connection.info("Verificando a Existência de sockets fantasma...")

        $sockets_conectados.each do |socket_conectado|
          socket_valido = $lista_telemetria.select{|telemetria| telemetria[:socket] == socket_conectado[:socket] }

          if socket_valido.blank? and socket_conectado[:hora] < 2.minutes.ago
            socket_conectado[:socket].close_connection
            logger_connection.info("SOCKET FANTASMA DETECTADO E DESCONECTADO : #{socket_conectado[:socket]}")
            $sockets_conectados.delete_if {|s| s[:socket] == socket_conectado[:socket] }
          end
        end
      end

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
      end
      EventMachine.start_server ip, porta, AnalogicProcess
    }
  end
end
