# encoding: utf-8
require_relative '../service/selecionar_pacote.rb'

class Evento < ActiveRecord::Base
  self.table_name = 'main.eventos'

  include Logging
  belongs_to :tipo_evento
  belongs_to :status
  #belongs_to :telemetria
  has_many :medidas_eventos

  def self.persistir_evento(eventos)
    reporte_faixa = false
    reporte_sinal = false
    reporte_energia = false
    reporte_temperatura = false
    colecao_medida_evento = []
    eventos.each do |evento|
      codigo_evento = 0
      equipamento = Equipamento.includes(:medidas, medidas: :faixas).find(evento[:id_equipamento])
      equipamento_medidas = equipamento.medidas_equipamento evento
      equipamento_medidas.each do |medida|
          faixa_atual = medida.faixas.select {|s| s.minimo.to_i >= evento[CODIGOS_MEDIDAS[medida.id_local].to_sym].to_i && s.maximo.to_i <= evento[CODIGOS_MEDIDAS[medida.id_local].to_sym].to_i}.first
          status_faixa = faixa_atual.present? ? faixa_atual.status_faixa : ALARME
          codigo_evento =
            if evento[:tipo_pacote].present?
              evento[:tipo_pacote]
            else
              SelecionarPacote.new({codigo_atual: codigo_evento, codigo_pacote: evento[:codigo_pacote], status_faixa: status_faixa}).seleciona_pacote
            end
          if status_faixa.to_i == ALERTA || status_faixa.to_i == ALARME
            reporte_faixa = true if medida.reporte_medida_id == REPORTE_FAIXA
            reporte_sinal = true if medida.reporte_medida_id == REPORTE_SINAL
            reporte_energia = true if medida.reporte_medida_id == REPORTE_ENERGIA
            reporte_temperatura = true if medida.reporte_medida_id == REPORTE_TEMPERATURA
          end

          medida_evento = MedidasEvento.new
          medida_evento.medida_id = medida.id
          medida_evento.id_local = medida.id_local
          medida_evento.valor = evento[CODIGOS_MEDIDAS[medida.id_local].to_sym]
          medida_evento.status_faixa = status_faixa
          medida_evento.reporte_medida_id = medida.reporte_medida_id
          colecao_medida_evento << medida_evento
      end
      if equipamento_medidas.present?
        novo_evento = Evento.new
        novo_evento.equipamento_id = equipamento.id
        novo_evento.status_id = Status.find_by_codigo(codigo_evento).id
        novo_evento.reporte_faixa = reporte_faixa
        novo_evento.reporte_sinal = reporte_sinal
        novo_evento.reporte_energia = reporte_energia
        novo_evento.reporte_temperatura = reporte_temperatura

        if novo_evento.save
          colecao_medida_evento.each do |med_evento|
            med_evento.evento_id = novo_evento.id
            med_evento.save
          end
          colecao_medida_evento = []
        end
      else
        Logging.warn "Evento não foi persistido pois ainda não existem medidas para o equipamento  #{equipamento.nome} e ID #{equipamento.id}"
      end
    end
  end

  def self.persiste_evento_configuracao(equipamentos_evento, medidas)
    id_configuracao_inicial_analogica = 21
    id_inicializacao_analogica = 20

    equipamentos_evento.each do |equipamento|
      ultima_inicializacao = Evento.where(status_id: id_inicializacao_analogica, equipamento_id: equipamento, created_at: Time.now().beginning_of_day..Time.now().end_of_day).includes(:status).last
      evento = Evento.create(equipamento_id: equipamento, status_id: id_configuracao_inicial_analogica, reporte_faixa: false, reporte_energia: false, reporte_sinal: false, reporte_temperatura: false, nivel_sinal: ultima_inicializacao ? ultima_inicializacao.nivel_sinal : nil)

     medida = medidas.select {|med| med.equipamento_id == evento.equipamento_id}.first

     medida_evento = MedidasEvento.new
     medida_evento.medida_id = medida.id
     medida_evento.id_local = medida.id_local
     medida_evento.valor = 0
     medida_evento.status_faixa = 1
     medida_evento.reporte_medida_id = medida.reporte_medida_id
     medida_evento.evento_id = evento.id
     medida_evento.save
    end
  end

  def self.persistir_inicializacao equipamentos, pacote, status_inicializacao: 20
    equipamentos.each do |equipamento|
      new_evento = Evento.new
      new_evento.equipamento_id = equipamento[:id_equipamento]
      new_evento.status_id = status_inicializacao
      new_evento.reporte_faixa = false
      new_evento.reporte_energia = false
      new_evento.reporte_sinal = false
      new_evento.reporte_temperatura = false
      new_evento.nivel_sinal = pacote[:DBM]
      if new_evento.save
        Logging.info "O novo evento de Inicialização foi persistido com sucesso para o equipamento de ID #{equipamento[:id_equipamento]}".blue
      else
        Logging.error "Houveram erros ao persistir o evento de Inicialização para o equipamento #{equipamento[:id_equipamento]}"
      end
    end
  end
end
