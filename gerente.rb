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
      # @timer = EventMachine::PeriodicTimer.new(30) do
        # logger.info "Checando tabela de saida...."
        # GerenteModule.checar_saida
      # end
      EventMachine::connect @ip, @porta, GerenteModule
    }
  end
end
