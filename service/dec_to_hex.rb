require "ipaddress"

class DecToHex
  # Public: Retorna a String com IP, PORTA e HOST da classe.
  attr :ip, :port, :host

  # Public: Inicializa a classe DecToHex
  #
  # args - Hash contendo os parâmetros de inicialização (default: {}):
  #       :ip - ip a ser convertido (opcional)
  #       :port - porta a ser convertido (opcional)
  #       :host - host a ser convertido (opcional)
  def initialize(args = {})
    @ip = args[:ip]
    @port = args[:port]
    @host = args[:host]
  end

  # Internal: Converte um IP em DECIMAL para HEXADECIMAL
  #
  # ip_arr - Array contendo os 3 octetos do IP
  #
  # Examples
  #
  #   DecToHex.new({ip: '127.0.0.1'}).ip_to_hex
  #   # => "7F000001"
  #
  #   DecToHex.new({ip: '127.0.0.999'}).ip_to_hex
  #   # => nil
  #
  # Retorna o IP em hexadecimal caso o mesmo seja válido e nil caso inválido.
  def ip_to_hex
    if ip_is_valid?
      ip_arr = ip.split('.').map(&:to_i)
      "%02X%02X%02X%02X" % ip_arr
    end
  end

  # Internal: Converte uma PORTA em DECIMAL para HEXADECIMAL
  #
  # Examples
  #
  #   DecToHex.new({port: '5580'}).port_to_hex
  #   # => "15CC"
  #
  # Retorna a PORTA em hexadecimal.
  def port_to_hex
    ("%002X" % port.to_i).rjust(4,'0')
  end

  # Internal: Converte um HOST em DECIMAL para HEXADECIMAL
  #
  # Examples
  #
  #   DecToHex.new({host: 'amz'}).host_to_hex
  #   # => "616D7A"
  #
  # Retorna o HOST em hexadecimal.
  def host_to_hex
    host.split('').map{|m| m.unpack('U')[0].to_s(16).upcase}.join()
  end

  # Internal: Converte um IP e uma PORTA em DECIMAL para HEXADECIMAL
  #
  # Examples
  #
  #   DecToHex.new({ip: '127.0.0.1', port: 5580}).ip_port_to_hex
  #   # => "7F00000115CC"
  #
  # Retorna o IP e a PORTA em hexadecimal.
  def ip_port_to_hex
    "#{ip_to_hex}#{port_to_hex}"
  end

  private
  # Private: Valida se um IP é valido
  #
  # Retorna true caso o ip seja válido e false caso não seja.
  def ip_is_valid?
    IPAddress.valid? ip
  end
end
