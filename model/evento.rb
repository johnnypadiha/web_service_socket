# encoding: utf-8
class Evento < ActiveRecord::Base
  self.table_name = 'main.eventos'

  include Logging
  belongs_to :tipo_evento
  belongs_to :status
  #belongs_to :telemetria
  has_many :medidas_eventos

  def self.persistir_evento(eventos)
    codigo_evento = 0
    reporte_faixa = false
    reporte_sinal = false
    reporte_energia = false
    reporte_temperatura = false
    colecao_medida_evento = []
    eventos.each do |evento|
      equipamento = Equipamento.includes(:medidas, medidas: :faixas).find(evento[:id_equipamento])
      equipamento_medidas = equipamento.medidas_equipamento evento
      equipamento_medidas.each do |medida|
          faixa_atual = medida.faixas.select {|s| s.minimo.to_i >= evento[medida.codigo_medida.to_sym].to_i && s.maximo.to_i <= evento[medida.codigo_medida.to_sym].to_i}.first
          status_faixa = faixa_atual.present? ? faixa_atual.status_faixa : 1

          case status_faixa.to_i
          when 3
            codigo_evento = LEITURA_INSTANTANEA_OK unless codigo_evento == LEITURA_INSTANTANEA_ALARME || codigo_evento == LEITURA_INSTANTANEA_ALERTA
          when 2
            codigo_evento = LEITURA_INSTANTANEA_ALERTA unless codigo_evento == LEITURA_INSTANTANEA_ALARME
          when 1
            codigo_evento = LEITURA_INSTANTANEA_ALARME
          end

          if status_faixa.to_i == 2 || status_faixa.to_i == 1
            reporte_faixa = true if medida.reporte_medida_id == REPORTE_FAIXA
            reporte_sinal = true if medida.reporte_medida_id == REPORTE_SINAL
            reporte_energia = true if medida.reporte_medida_id == REPORTE_ENERGIA
            reporte_temperatura = true if medida.reporte_medida_id == REPORTE_TEMPERATURA
          end

          medida_evento = MedidasEvento.new
          medida_evento.medida_id = medida.id
          medida_evento.valor = evento[medida.codigo_medida.to_sym]
          medida_evento.status_faixa = status_faixa
          medida_evento.reporte_medida_id = medida.reporte_medida_id
          colecao_medida_evento << medida_evento
      end
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
        logger.info "O novo evento de Inicialização foi persistido com sucesso para o equipamento #{equipamento[:id_equipamento]} - #{equipamento[:nome]}".blue
      else
        logger.info "Houveram erros ao persistir o evento de Inicialização para o equipamento #{equipamento[:id_equipamento]} - #{equipamento[:nome]}".red
      end
    end
  end
end
