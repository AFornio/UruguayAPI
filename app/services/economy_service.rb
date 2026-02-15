# Indicadores económicos vigentes de Uruguay.
#
# Obtiene valores actualizados de BPC, UR, UI, salario mínimo y otros indicadores
# desde la tabla de valores actuales del BPS.
#
# Fuente: https://www.bps.gub.uy/5478/valores-actuales.html
# Actualización: bimestral (los valores se publican por mes en columnas).
class EconomyService
  BPS_URL = 'https://www.bps.gub.uy/5478/valores-actuales.html'

  INDICATOR_KEYS = {
    'Base de Prestaciones y Contribuciones' => :bpc,
    'Salario mínimo nacional' => :minimum_wage,
    'Salario mínimo Servicio Doméstico' => :domestic_minimum_wage,
    'Unidad Reajustable' => :ur,
    'Unidad Indexada' => :ui,
    'Cuota mutual' => :mutual_quota,
    'Costo Promedio Equivalente' => :cpe,
    'Base Ficta de Contribución' => :bfc
  }.freeze

  def self.fetch_values
    response = HTTParty.get(BPS_URL)
    doc = Nokogiri::HTML(response.body)

    table = doc.css('table').first
    return {} unless table

    rows = table.css('tr')
    return {} if rows.length < 2

    values = {}

    rows[1..].each do |row|
      cells = row.css('td')
      next if cells.empty?

      indicator_text = cells[0].text.strip
      key = find_key(indicator_text)
      next unless key

      raw_value = latest_value(cells[1..])
      next unless raw_value

      values[key] = { value: parse_value(raw_value), currency: 'UYU' }
    end

    values
  end

  def self.find_key(text)
    INDICATOR_KEYS.each do |pattern, key|
      return key if text.include?(pattern)
    end
    nil
  end

  def self.parse_value(raw)
    raw.delete('$').strip.tr('.', '').tr(',', '.').to_f
  end

  def self.latest_value(cells)
    cells.reverse_each do |cell|
      text = cell.text.strip
      return text unless text.empty?
    end
    nil
  end

  private_class_method :find_key, :parse_value, :latest_value
end
