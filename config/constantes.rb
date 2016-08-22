# Constantes utilizadas na aplicação

BASE_HEXA = 16
BASE_DEC  = 10
BASE_BIN  = 2
BASE_SEGUNDOS = 60

PERIODICO_OK = 0
PERIODICO_ALARMADO = 1
CONFIGURACAO = 3
INICIALIZACAO = 4
LEITURA_INSTANTANEA = 5
CONTAGEM_ALARMAR = 7
NORMALIZACAO = 8
ALARME_INSTANTANEO = 9
ID_RECEBIDO = 9999
CONFIRMACAO_COMANDOS = 2

ZERA_CONTAGEM = 0

QTDE_ANALOGICAS = 16
QTDE_DIGITAIS   = 4
QTDE_NEGATIVAS  = 4

SIZE_PERIODICO_OK = 72
SIZE_CONFIGURACAO = 190
SIZE_PACOTES_DEFAULT = 88
SIZE_ID_TELEMETRIA = 4
SIZE_CONFIRMACAO_COMANDOS = 12
SIZE_CONFIRMACAO_IP_PORTA_HOST = 10

TOTAL_MEDIDAS = 24

INICIALIZACAO_OK = 12
INICIALIZACAO_ALERTA = 18
INICIALIZACAO_ALARME = 17

LEITURA_INSTANTANEA_OK = 11
LEITURA_INSTANTANEA_ALERTA = 20
LEITURA_INSTANTANEA_ALARME = 19

REPORTE_FAIXA = 1
REPORTE_ENERGIA = 2
REPORTE_SINAL = 3
REPORTE_TEMPERATURA = 3

OK = 1
ALERTA = 2
ALARME = 3

PACOTE_NORMALIZACAO = 15
PACOTE_NORMALIZACAO_ALERTA = 23
PACOTE_NORMALIZACAO_ALARME = 24

PACOTE_ALERTA = 13
PACOTE_ALERTA_OK = 25
PACOTE_ALERTA_ALARME = 26

PACOTE_ALARME = 14

CODIGOS_MEDIDAS = {
  1 => 'A1',
  2 => 'A2',
  3 => 'A3',
  4 => 'A4',
  5 => 'A5',
  6 => 'A6',
  7 => 'A7',
  8 => 'A8',
  9 => 'A9',
  10 => 'A10',
  11 => 'A11',
  12 => 'A12',
  13 => 'A13',
  14 => 'A14',
  15 => 'A15',
  16 => 'A16',
  17 => 'N1',
  18 => 'N2',
  19 => 'N3',
  20 => 'N4',
  21 => 'D1',
  22 => 'D2',
  23 => 'D3',
  24 => 'D4'
}

INICIO_DIGITAIS = 21
FIM_DIGITAIS = 24

INICIO_NEGATIVAS = 17
FIM_NEGATIVAS = 20

TEMPERATURA_DEFAULT = 20

#limite de tentativas de processamento da tabela saída analógica
LIMITE_TENTIVAS = 5

RESET_TELEMETRY = 6
INSTANT_READING = 2
CHANGE_PRIMARY_IP = 19
CHANGE_SECUNDARY_IP = 20
CHANGE_HOST = 21
CHANGE_PORT = 22
CHANGE_FAIXA_TIMER = 4
