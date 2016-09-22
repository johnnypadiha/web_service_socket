module Logging
  def logger_id
    Logging.logger_id
  end

  def logger_socket
    Logging.logger_socket
  end

  def logger_connection
    Logging.logger_telemetria_connection
  end

  def logger
    Logging.logger
  end

  def self.logger_id
    @logger_id ||= Logger.new("log_id.log")
  end

  def self.logger
    @logger ||= Logger.new("log.log")
  end

  def self.logger_telemetria_connection
    @logger_telemetria_connection ||= Logger.new("telemetry_connection.log")
  end

  def self.logger_socket
    @logger_socket ||= Logger.new("telemetry_socket.log")
  end

  def self.method_missing(prioridade, *args)
    case prioridade
    when :info
      Logging.logger.info("#{args[0]}")
    when :debug
      Logging.logger.debug("#{args[0]}".green)
    when :fatal
      Logging.logger.fatal("#{args[0]}".red)
    when :error
      Logging.logger.error("#{args[0]}".red)
    when :warn
      Logging.logger.warn("#{args[0]}".yellow)
    else
      Logging.logger.fatal("O metodo chamado não existe!")
    end
  end

end
