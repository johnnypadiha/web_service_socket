module Logging

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
end
