#Web_server_analogico ![Build Status](https://img.shields.io/badge/BETA-V%201.0-green.svg)

###iniciando o server pelo puma
```sh
$ bundle exec puma -d -C config/puma.rb
```

### códigos das operadoras no pacote de configuração
Metodo:   ProcessarPacotes::configuracao
variável: configuracao_hex[:operadora]
            1 - operadora = "TIM"
            2 - operadora = "VIVO M2M / SMARTCENTER"
            3 - operadora = "BRASIL TELECOM"
            4 - operadora = "VIVO"
            5 - operadora = "OI"
