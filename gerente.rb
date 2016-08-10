require 'rubygems'
require 'eventmachine'

require './api_module/gerente_module.rb'

include Logging
class Gerente
  def initialize(ip, porta)

    @ip = ip
    @porta = porta

    start_gerente
  end

  def start_gerente
    EventMachine.run {
      EventMachine.error_handler do |e|
        logger.info "Exception during event: #{e.message} (#{e.class})".red
        logger.info (e.backtrace || [])[0..10].join("\n")
      end
      @timer = EventMachine::PeriodicTimer.new(5) do
        logger.info "Checando tabela de saida...."
        GerenteModule.checar_saida
      end
      EventMachine::connect @ip, @porta, GerenteModule
    }
  end
end
