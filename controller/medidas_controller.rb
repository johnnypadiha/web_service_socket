class MedidasController

  def self.create_medidas(id_telemetria, analogicas, negativas, digitais)

    analogicas.each do |key, value|
      medida = Medida.new
      medida.codigo_medida = key.to_s
      medida.equipamento_id = id_telemetria
      medida.timer = value[:timer]
      medida.created_at = Time.now
      medida.updated_at = Time.now
      if medida.save
        faixa = Faixa.new
        faixa.medida_id = medida.id
        faixa.minimo = value[:minimo]
        faixa.maximo = value[:maximo]
        faixa.save
      end
    end

    negativas.each do |key, value|
      medida = Medida.new
      medida.codigo_medida = key.to_s
      medida.equipamento_id = id_telemetria
      medida.timer = value[:timer]
      medida.created_at = Time.now
      medida.updated_at = Time.now
      if medida.save
        faixa = Faixa.new
        faixa.medida_id = medida.id
        faixa.minimo = value[:minimo]
        faixa.maximo = value[:maximo]
        faixa.save
      end
    end

    digitais.each do |key, value|
      medida = Medida.new
      medida.codigo_medida = key.to_s
      medida.equipamento_id = id_telemetria
      medida.timer = value[:timer]
      medida.estado_normal = value[:normal]
      medida.created_at = Time.now
      medida.updated_at = Time.now
      medida.save
    end
  end
end
