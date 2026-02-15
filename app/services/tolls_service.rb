# Servicio de peajes en Uruguay.
#
# Obtiene tarifas vigentes y ubicaciones de los peajes nacionales mediante scraping.
#
# Fuentes:
#   - Tarifas: https://www.gub.uy/ministerio-transporte-obras-publicas/politicas-y-gestion/tarifas
#   - Ubicaciones: https://datosuruguay.com/peajes
class TollsService
  RATES_URL = 'https://www.gub.uy/ministerio-transporte-obras-publicas/politicas-y-gestion/tarifas'
  LOCATIONS_URL = 'https://datosuruguay.com/peajes'

  def self.fetch_all
    rates = fetch_rates
    locations = fetch_locations

    { rates:, locations:, currency: 'UYU' }
  end

  def self.fetch_rates
    response = HTTParty.get(RATES_URL)
    doc = Nokogiri::HTML(response.body)

    table = doc.css('table').first
    return [] unless table

    rows = table.css('tr')
    return [] if rows.empty?

    rates = []

    rows.each_with_index do |row, index|
      next if index.zero? # Skip header row

      cells = row.css('td')
      next if cells.length < 4

      category = cells[0].text.strip
      basic = cells[1].text.strip
      telepeaje = cells[2].text.strip
      sucive = cells[3].text.strip

      rates << {
        category:,
        basic:,
        telepeaje:,
        sucive:
      }
    end

    rates
  end

  def self.fetch_locations
    response = HTTParty.get(LOCATIONS_URL)
    doc = Nokogiri::HTML(response.body)

    locations = []

    doc.css('ul li').each do |li|
      route_element = li.css('strong').first
      next unless route_element

      route = route_element.text.strip.delete_suffix(':')
      text = li.text.sub(route_element.text, '').strip.delete_prefix(':').strip

      text.split(/\s+y\s+|,\s+/).each do |toll_text|
        toll_text = toll_text.strip.delete_suffix('y').strip
        next if toll_text.empty?

        if toll_text =~ /(.+?)\s*\(km\s*([\d,.]+)\)/
          name = Regexp.last_match(1).strip
          km = Regexp.last_match(2).strip.tr(',', '.')

          locations << { name:, route:, km: }
        end
      end
    end

    locations
  end

  private_class_method :fetch_rates, :fetch_locations
end
