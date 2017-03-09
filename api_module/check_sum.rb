# encoding: utf-8
module CheckSum
  # Internal : Gera o Validador CheckSum para todos os pacotes a enviar para a telemetria
  #
  # comando : String que possui um comando no formato hexadecimal
  # i : Integer que armazena o contador para a flag de saida do while
  # cs : Inteiro que armnazena o calculo do CheckSum do pacote
  # byte_pacote : String que armazena dois caracteres do conteudo da variavel comando
  #
  # retorno : variavel comando com o CheckSum
  def gerar_check_sum(comando)
    i = 0
    cs = 0
    while i < comando.size
        if i % 2 == 1
          byte_pacote = comando[i - 1 .. i]
          cs ^= byte_pacote.hex.to_s(BASE_DEC).to_i
        end
      i += 1
    end
    cs.to_s(BASE_HEXA).rjust(2,'0').upcase

    comando += cs.to_s(BASE_HEXA).rjust(2,'0').upcase

    comando
  end
end
