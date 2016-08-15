require "ipaddress"

class DecToHex
  attr :ip, :port, :host
  def initialize(args = {})
    @ip = args[:ip]
    @port = args[:port]
    @host = args[:host]
  end

  def ip_to_hex
    if validate_ip ip
      ip_arr = ip.split('.').map(&:to_i)
      "%02X%02X%02X%02X" % ip_arr
    end
  end

  def port_to_hex
    "%02X" % port.to_i
  end

  def host_to_hex
    host.split('').map{|m| m.unpack('U')[0].to_s(16).upcase}.join()
  end

  def ip_port_to_hex
    "#{ip_to_hex}#{port_to_hex}"
  end

  private
  def validate_ip ip
    IPAddress.valid? ip
  end
end

#Ip e Porta
# DecToHex.new({ip: '69.162.90.34', port: 5580}).ip_port_to_hex
#IP
# DecToHex.new({ip: '69.162.90.34'}).ip_to_hex
#Porta
#DecToHex.new({port: '5580'}).port_to_hex
#Host
#DecToHex.new({host: 'amz'}).host_to_hex
