# \ -s puma
require 'rubygems'
require 'active_record'
require 'pg'
require 'logger'
require 'eventmachine'
require 'colorize'
require './logging.rb'
require './server.rb'
require './gerente.rb'
require './api_module/analogic_process.rb'
require './api_module/pacotes.rb'
require './config/constantes.rb'
Dir.glob('./model/*.rb') { |file| load file }

$path = File.dirname(File.expand_path(__FILE__))

ip = '45.55.233.137'
# ip = '192.168.0.150'
# ip = '192.168.0.120'
# ip = '192.168.0.225'

porta = 5580

@pasta_pids = "#{$path}/tmp/pids"

 ActiveRecord::Base.configurations = YAML.load(IO.read("#{$path}/db/config.yml"))
 ActiveRecord::Base.establish_connection(:production)
 # ActiveRecord::Base.establish_connection(:development)
 ActiveRecord::Base.default_timezone = :local
 ActiveRecord::Base.logger = Logger.new('sql_logger.log')

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

fork do
  # pega o pid do gerente e armazena na pastas de pids
  pid = Process.pid
  arq = File.new("#{@pasta_pids}/gerente.pid", 'w')
  arq.puts pid.to_i
  arq.close

  sleep 10
  Gerente.new(ip, porta)
end

puma_pid
WebService.new(ip, porta)
