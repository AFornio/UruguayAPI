# Indicadores de inflación y variación de precios/salarios de Uruguay.
#
# Obtiene las variaciones interanuales del IPC, IMS, IMSN e ICCV
# desde el sidebar de indicadores del INE.
#
# Fuente: https://www.ine.gub.uy/ipc-indice-de-precios-del-consumo
# Actualización: mensual (el INE publica nuevos valores cada mes).
class InflationService
  INE_URL = 'https://www.ine.gub.uy/ipc-indice-de-precios-del-consumo'

  INDICATOR_PATTERN = /\A(.+?)\s*\(Var\.\s*12\s*meses?\)\s*(\d{2}\/\d{2}):\s*([\d,]+)\s*%/i

  INDICATOR_KEYS = {
    'Precios del Consumo' => :ipc,
    'Medio de Salarios Nominales' => :imsn,
    'Medio de Salarios' => :ims,
    'Costo de la Construcción' => :iccv
  }.freeze

  def self.fetch_indicators
    response = HTTParty.get(INE_URL, verify: false)
    doc = Nokogiri::HTML(response.body)

    indicators = {}

    doc.css('a').each do |link|
      text = link.text.strip.gsub(/\s+/, ' ')
      match = text.match(INDICATOR_PATTERN)
      next unless match

      name = match[1]
      period = match[2]
      variation = match[3].tr(',', '.').to_f

      key = find_key(name)
      next unless key

      indicators[key] = { period:, variation_12m: variation }
    end

    indicators
  end

  def self.find_key(name)
    INDICATOR_KEYS.each do |pattern, key|
      return key if name.include?(pattern)
    end
    nil
  end

  private_class_method :find_key
end
