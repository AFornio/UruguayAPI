# Servicio de tarifas eléctricas de UTE (Administración Nacional de Usinas
# y Trasmisiones Eléctricas) para el sector residencial.
#
# Tarifas disponibles:
#   - TRS: Tarifa Residencial Simple (por escalones de consumo)
#   - TRD: Tarifa Residencial Doble Horario (punta / fuera de punta)
#   - TRT: Tarifa Residencial Triple Horario (punta / llano / valle)
#
# Las tarifas se actualizan una vez al año (1 de enero).
# Precios en $/kWh sin IVA (22%).
#
# Fuente: https://www.ute.com.uy/clientes/soluciones-para-el-hogar/planes-hogar/opciones-tarifarias-para-hogares
class UteService
  TARIFFS_URL = 'https://www.ute.com.uy/clientes/soluciones-para-el-hogar/planes-hogar/opciones-tarifarias-para-hogares'

  VAT_RATE = 0.22

  def self.fetch_tariffs
    response = HTTParty.get(TARIFFS_URL)
    doc = Nokogiri::HTML(response.body)

    tables = doc.css('table')
    return {} if tables.empty?

    tariffs = {}
    tariffs[:trs] = extract_trs(tables)
    tariffs[:trd] = extract_time_based(tables, 'punta', 'fuera de punta')
    tariffs[:trt] = extract_time_based(tables, 'punta', 'valle', 'llano')

    tariffs.compact_blank!
    tariffs[:vat_rate] = VAT_RATE
    tariffs[:currency] = 'UYU'
    tariffs[:note] = 'Precios sin IVA (22%)'
    tariffs
  end

  def self.extract_trs(tables)
    tables.each do |table|
      rows = table.css('tr')
      next if rows.length < 2

      trs_data = []
      rows[1..].each do |row|
        cells = row.css('td, th')
        next if cells.length < 2

        label = cells[0].text.strip.downcase
        next unless label.include?('escalón') || label.include?('kwh')

        price_text = cells[1].text.strip
        price = parse_price(price_text)
        next unless price

        tier = parse_tier(label)
        trs_data << { tier:, price_per_kwh: price } if tier
      end

      return { type: 'simple', tiers: trs_data } if trs_data.any?
    end

    nil
  end

  def self.extract_time_based(tables, *period_keywords)
    tables.each do |table|
      rows = table.css('tr')
      next if rows.length < 2

      periods = []
      rows[1..].each do |row|
        cells = row.css('td, th')
        next if cells.length < 2

        label = cells[0].text.strip.downcase
        price_text = cells[1].text.strip
        price = parse_price(price_text)
        next unless price

        matched_period = period_keywords.sort_by { |kw| -kw.length }.find { |kw| label.include?(kw) }
        next unless matched_period

        periods << { period: matched_period, price_per_kwh: price }
      end

      return { type: period_keywords.length == 2 ? 'doble_horario' : 'triple_horario', periods: } if periods.length == period_keywords.length
    end

    nil
  end

  def self.parse_price(text)
    cleaned = text.gsub(/[^\d,.]/, '').tr('.', '').tr(',', '.')
    value = cleaned.to_f
    value.positive? ? value : nil
  end

  def self.parse_tier(label)
    case label
    when /1.*100/ then '1-100 kWh'
    when /101.*600/ then '101-600 kWh'
    when /601/ then '601+ kWh'
    end
  end

  private_class_method :extract_trs, :extract_time_based, :parse_price, :parse_tier
end
