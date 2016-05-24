require 'logger'
require 'eventmachine'
require './api_module/analogic_process.rb'
require './api_module/logging.rb'
class WebService
  include Logging

  def initialize
    api
  end

  def api
    logger.info("RUN API --------------------")
    EventMachine.run {
      EventMachine.start_server "192.168.0.10", 8081, AnalogicProcess
    }
  end
end

WebService.new
