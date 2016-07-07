require 'rubygems'
require 'eventmachine'

class GerenteModule < EventMachine::Connection
  def initialize(*args)
    super
    $gerente = self
  end

  def post_init
   send_data '<0000>'
  end

  def receive_data(data)
    logger.info data
  end

  def unbind
    #@timer.cancel
    logger.info 'Gerente disconectado!'
  end

  def self.checar_saida
    saida = Saida.where('cancelado = ? and data_processamento is ?', false, nil).first
    GerenteModule.processar_comandos(saida) if saida
    #$gerente.send_data '<00000001>'
  end

  def self.processar_comandos(saida)
    if saida.tentativa.to_i  <= 5
      saida.update(tentativa: saida.tentativa.to_i + 1)
      case saida.tipo_comando.to_i
      when 04
        id_telemetria = saida.codigo_equipamento.to_s.rjust(4,'0')
        logger.info id_telemetria

        if $gerente.send_data "<0000#{id_telemetria}02FFFF>"
          saida.update(data_processamento: Time.now)
        end
      end
    else
      saida.update(cancelado: true, data_processamento: Time.now)
    end
  end

  def self.obter_pacote(pacote)
    pacote = Pacotes.formatador(pacote)

    pacote = pacote[8..pacote.size]
    "<#{gerar_check_sum(pacote)}>"
  end
end
