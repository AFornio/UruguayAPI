# Ferias vecinales de Montevideo: día, horario, barrio, tramos de calle y ubicación.
#
# Fuente: la capa "Ferias vecinales de Montevideo" del geoserver de la Intendencia
# (ide:V_SF_FERIAS_GEOM). Cada fila es un tramo; los tramos con el mismo código y día
# son una sola feria (Juan Paullier va de Chaná a Guaná y sigue de Guaná a Charrúa).
class StreetMarketsService
  URL = 'https://geoserver.montevideo.gub.uy/geoserver/ows?service=WFS&version=2.0.0&request=GetFeature' \
        '&typeNames=ide:V_SF_FERIAS_GEOM&outputFormat=application/json&srsName=EPSG:4326&count=2000'.freeze
  # Lunes = 1 ... domingo = 7 (ISO 8601, igual que Date#cwday y DateTime.weekday en Dart).
  WEEKDAYS = { 'lunes' => 1, 'martes' => 2, 'miercoles' => 3, 'jueves' => 4, 'viernes' => 5, 'sabado' => 6,
               'domingo' => 7 }.freeze
  FOOD = 'Feria alimentaria'.freeze

  class << self
    def fetch_all
      features = JSON.parse(Scraper.get(URL).body).fetch('features')
      markets = features.group_by { |feature| feature['properties'].values_at('COD_FERIA', 'DIA') }.values
      markets.filter_map { |segments| market(segments) }.sort_by { |m| [m[:weekday], m[:name]] }
    end

    private

    def market(segments)
      props = segments.pluck('properties')
      weekday = weekday_of(props.first['DIA'])
      return if weekday.nil?

      latitude, longitude = center(segments.pluck('geometry'))
      opens, closes = hours(props)
      {
        id: "#{props.first['COD_FERIA']}-#{weekday}", name: name(props), neighborhood: neighborhood(props),
        weekday:, opens:, closes:, food: props.any? { |p| p['TIPO'] == FOOD }, segments: segments(props),
        latitude:, longitude:
      }
    end

    def weekday_of(day)
      WEEKDAYS[I18n.transliterate(day.to_s).downcase.strip]
    end

    # El nombre más repetido entre los tramos (alguno puede venir con espacios de más).
    def name(props)
      props.map { |p| p['NOMBRE'].to_s.squish }.tally.max_by(&:last).first
    end

    def neighborhood(props)
      props.first['BARRIO'].to_s.squish.titleize
    end

    # De la apertura más temprana al cierre más tardío entre los tramos.
    def hours(props)
      [props.pluck('HORA_INICIO').compact.min, props.pluck('HORA_FIN').compact.max]
    end

    # El tramo principal primero; los que la Intendencia describe como "continuación" después.
    def segments(props)
      texts = props.map { |p| p['UBICACION'].to_s.squish }.compact_blank.uniq
      texts.sort_by { |text| I18n.transliterate(text).downcase.match?(/\A(a )?continuacion/) ? 1 : 0 }
    end

    # Promedio de los vértices de todos los tramos: alcanza para medir distancias y abrir el mapa.
    def center(geometries)
      points = geometries.compact.flat_map { |geometry| geometry['coordinates'].flatten(1) }
      return [nil, nil] if points.empty?

      [points.sum { |_, lat| lat } / points.size, points.sum { |lng, _| lng } / points.size].map { |v| v.round(6) }
    end
  end
end
