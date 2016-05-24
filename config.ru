# \ -s puma
require 'rubygems'
require 'logger'
require 'eventmachine'
require './logging.rb'
require './server.rb'
require './api_module/analogic_process.rb'

$path = File.dirname(File.expand_path(__FILE__))

ip = '45.55.233.137'

# ip = '192.168.0.150'
porta = 5580

@pasta_pids = "#{$path}/tmp/pids"

# Internal: cria a pasta para armazenar os pids e armazena o PID do puma
#
# pid = Numero do processo do puma
# arq = arquivo de texto que irá armazenar o numero do pid
#
def puma_pid
  pid = Process.pid
  FileUtils.mkdir_p(@pasta_pids) unless File.directory?(@pasta_pids)
  arq = File.new("#{@pasta_pids}/puma.pid", 'w')
  arq.puts pid.to_i
  arq.close
end

puma_pid
WebService.new(ip, porta)
