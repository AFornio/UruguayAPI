# Water outages service for OSE (Obras Sanitarias del Estado).
#
# Fetches the water supply interruption notices published by OSE via scraping.
#
# The page is a GeneXus grid that embeds its rows as a JSON array inside a
# hidden input (`W0006GridContainerDataV`), so it requires neither running
# JavaScript nor replaying the AJAX postback: a plain GET is enough.
#
# Source: https://cortes.ose.com.uy/serviciosAlCliente.verAvisos.aspx
class OseService
  OUTAGES_URL = 'https://cortes.ose.com.uy/serviciosAlCliente.verAvisos.aspx'
  GRID_INPUT = 'W0006GridContainerDataV'

  def self.fetch_outages
    response = HTTParty.get(OUTAGES_URL)
    doc = Nokogiri::HTML(response.body)

    input = doc.at_css("input[name='#{GRID_INPUT}']")
    return { source: 'OSE', count: 0, outages: [] } unless input

    rows = JSON.parse(input['value'])
    outages = rows.filter_map { |row| parse_row(row) }

    { source: 'OSE', count: outages.length, outages: }
  end

  # Turns a raw grid row (array of ~158 cells, mostly empty) into a structured
  # outage. Returns nil when the row is empty.
  def self.parse_row(row)
    cells = row.map { |cell| cell.is_a?(String) ? cell.strip.gsub(/\s+/, ' ') : '' }
    return nil if cells.all?(&:empty?)

    department, locality = parse_location(cells)

    {
      type: find_match(cells, /SUMINISTRO/i),
      published_at: parse_published(cells),
      department:,
      locality:,
      affected_area: value_after(cells, 'Zona afectada:'),
      starts_at: value_after(cells, 'Desde:'),
      ends_at: value_after(cells, 'Hasta:'),
      reason: value_after(cells, 'Motivo:'),
      additional_info: value_after(cells, 'Información adicional:')
    }
  end

  # Returns the first non-empty cell after the cell that exactly matches
  # `label`. The relevant cells are labeled within the grid.
  def self.value_after(cells, label)
    index = cells.index { |cell| cell == label }
    return '' unless index

    cells[(index + 1)..].find { |cell| !cell.empty? } || ''
  end

  def self.find_match(cells, regex)
    cells.find { |cell| cell.match?(regex) } || ''
  end

  # Extracts [department, locality] from the
  # "Localidad <X>, Departamento de <Y>" cell.
  def self.parse_location(cells)
    cell = find_match(cells, /Localidad .+ Departamento de /i)
    match = cell.match(/Localidad\s+(.+?),\s*Departamento de\s+(.+)/i)
    return ['', ''] unless match

    [match[2].strip, match[1].strip]
  end

  # Extracts "dd/mm/yyyy HH:MM" from the
  # "Fecha de publicación: <date> - Hora: <time>" cell.
  def self.parse_published(cells)
    cell = find_match(cells, /Fecha de publicaci/i)
    match = cell.match(%r{(\d{2}/\d{2}/\d{4}).*?(\d{1,2}:\d{2})})
    return '' unless match

    "#{match[1]} #{match[2]}"
  end

  private_class_method :parse_row, :value_after, :find_match, :parse_location, :parse_published
end
