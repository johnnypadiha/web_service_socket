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
require './service/dec_to_hex.rb'
Dir.glob('./model/*.rb') { |file| load file }

$path = File.dirname(File.expand_path(__FILE__))

environment = ENV['RACK_ENV'] || 'development'

ip = '159.203.97.144' if environment == 'ojc_production'
ip = '104.236.115.92' if environment == 'amz_production'
ip = '45.55.233.137' if environment == 'homologacao'
ip = '192.168.15.13' if environment == 'development'

if environment == 'amz_production'
  porta = 5581
else
  porta = 5580
end

@pasta_pids = "#{$path}/tmp/pids"


 ActiveRecord::Base.configurations = YAML.load(IO.read("#{$path}/db/config.yml"))
 ActiveRecord::Base.establish_connection(environment.to_sym)
 ActiveRecord::Base.default_timezone = :local
 ActiveRecord::Base.logger = Logger.new('log/sql_logger.log')

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
