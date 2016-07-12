module Logging
 def logger_socket
   Logging.logger_socket
 end

 def logger_connection
   Logging.logger_telemetria_connection
 end

 def logger
   Logging.logger
 end

 def self.logger
   @logger ||= Logger.new("log.log")
 end

 def self.logger_telemetria_connection
   @logger_telemetria_connection ||= Logger.new("telemetry_connection.log")
 end

 def self.logger_socket
   @logger_telemetria_socket ||= Logger.new("telemetry_socket.log")
 end

 def self.method_missing(prioridade, *args)
   case prioridade
   when :info
     Logging.logger.info("#{args[0]}")
   when :debug
     Logging.logger.debug("#{args[0]}")
   when :fatal
     Logging.logger.fatal("#{args[0]}")
   when :error
     Logging.logger.error("#{args[0]}")
   when :warn
     Logging.logger.warn("#{args[0]}")
   else
     Logging.logger.fatal("O metodo chamado não existe!")
   end
 end

end
