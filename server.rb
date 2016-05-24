include Logging
class WebService

  def initialize(ip, porta)
    api(ip,porta)
  end

  def api(ip,porta)
    logger.info("RUN API --------------------")
    EventMachine.run {
      EventMachine.start_server ip, porta, AnalogicProcess
    }
  end
end
