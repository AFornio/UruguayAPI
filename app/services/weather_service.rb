# Servicio de pronóstico y condiciones meteorológicas para Uruguay.
#
# Consume endpoints JSON internos de INUMET (Instituto Uruguayo de Meteorología).
# Estos endpoints no están documentados oficialmente pero son utilizados por el
# frontend de inumet.gub.uy y por integraciones de Home Assistant.
#
# Fuentes:
#   - Pronóstico: https://www.inumet.gub.uy/reportes/pronosticos/pronosticoV4.json
#   - Estado actual: https://www.inumet.gub.uy/reportes/estadoActual/datos_inumet_ui_publica.mch
#   - Alertas: https://www.inumet.gub.uy/admin/check-avisos
#
# Créditos por el descubrimiento de los endpoints:
#   - https://github.com/matbott/ha-inumet-uruguay
#   - https://github.com/aronkahrs-us/inumet-weather-ha
class WeatherService
  FORECAST_URL = 'https://www.inumet.gub.uy/reportes/pronosticos/pronosticoV4.json'
  CURRENT_URL = 'https://www.inumet.gub.uy/reportes/estadoActual/datos_inumet_ui_publica.mch'
  ALERTS_URL = 'https://www.inumet.gub.uy/admin/check-avisos'
  ALERTS_DETAIL_URL = 'https://inumet.gub.uy/reportes/riesgo/advGral.mch'

  DEPARTMENT_ZONES = {
    'artigas' => 66, 'salto' => 66,
    'rivera' => 65, 'tacuarembo' => 65, 'cerro_largo' => 65,
    'paysandu' => 86, 'rio_negro' => 86, 'soriano' => 86, 'colonia' => 86,
    'durazno' => 67, 'flores' => 67, 'florida' => 67,
    'lavalleja' => 68, 'rocha' => 68, 'treinta_y_tres' => 68,
    'montevideo' => 88, 'canelones' => 88, 'san_jose' => 88,
    'maldonado' => 89
  }.freeze

  WEATHER_CONDITIONS = {
    '1' => 'Soleado', '2' => 'Parcialmente nublado', '3' => 'Parcialmente nublado',
    '4' => 'Nublado', '5' => 'Nublado', '6' => 'Cubierto',
    '7' => 'Lluvioso', '8' => 'Niebla', '10' => 'Tormentas eléctricas',
    '11' => 'Tormentas con lluvia', '12' => 'Ventoso', '13' => 'Nuboso',
    '17' => 'Nieve', '18' => 'Excepcional'
  }.freeze

  # Variables en el array de observaciones del endpoint de estado actual.
  VARIABLE_KEYS = {
    'TempAire' => :temperature,
    'HumRelativa' => :humidity,
    'DirViento' => :wind_direction,
    'IntViento' => :wind_speed_knots,
    'IntRafaga' => :wind_gust_knots,
    'PresAtmMar' => :pressure_hpa,
    'precipHoraria' => :precipitation_mm
  }.freeze

  KNOTS_TO_KMH = 1.852

  def self.fetch_forecast(department)
    zone_id = DEPARTMENT_ZONES[department]
    return nil unless zone_id

    response = HTTParty.get(FORECAST_URL)
    data = JSON.parse(response.body)

    items = data['items'].select { |i| i['zonaId'] == zone_id }
    return nil if items.empty?

    zone_name = items.first['zonaLarga']

    forecast_days = items.map { |item| format_forecast_day(item) }

    {
      department:,
      zone: zone_name,
      published_at: data['fechaPublicacion'],
      forecaster: data['pronosticador'],
      forecast: forecast_days
    }
  end

  def self.fetch_current(department)
    zone_id = DEPARTMENT_ZONES[department]
    return nil unless zone_id

    response = HTTParty.get(CURRENT_URL)
    data = JSON.parse(response.body)

    stations = data['estaciones']
    variables = data['variables']
    fechas = data['fechas']
    observations = data['observaciones']

    return nil unless stations && variables && observations

    department_stations = find_department_stations(stations, department)
    return nil if department_stations.empty?

    var_index = build_variable_index(variables)
    latest_time_index = fechas.length - 1

    station_data = department_stations.map do |station|
      station_index = stations.index(station)
      readings = extract_readings(observations, var_index, station_index, latest_time_index)

      {
        name: station['displayNamePublic'] || station['nombre'],
        latitude: station['latitud'],
        longitude: station['longitud'],
        readings:
      }
    end

    {
      department:,
      timestamp: fechas.last,
      stations: station_data
    }
  end

  def self.fetch_alerts
    response = HTTParty.get(ALERTS_URL)
    check = JSON.parse(response.body)

    return { has_alerts: false, alerts: [] } unless check['has_avisos']

    detail_response = HTTParty.get(ALERTS_DETAIL_URL)
    detail = JSON.parse(detail_response.body)

    { has_alerts: true, alerts: detail }
  end

  def self.departments
    DEPARTMENT_ZONES.keys.sort
  end

  # --- Métodos privados ---

  def self.format_forecast_day(item)
    result = {
      day: item['grupo'],
      temp_min: item['tempMin'],
      temp_max: item['tempMax'],
      weather_condition: WEATHER_CONDITIONS[item['estadoTiempo'].to_s] || item['estadoTiempo'],
      rain_probability: item['probLluvia']
    }

    if item['subgrupos']
      result[:periods] = item['subgrupos'].map do |sg|
        {
          period: sg['subgrupo'],
          description: sg['descripcion'],
          evolution: sg['evolucion'],
          extra: sg['descripcionExtra'],
          wind: sg['vientos'],
          weather_condition: WEATHER_CONDITIONS[sg['estadoTiempo'].to_s] || sg['estadoTiempo']
        }.compact_blank
      end
    end

    result
  end

  def self.find_department_stations(stations, department)
    dept_patterns = department_station_patterns(department)
    stations.select do |s|
      name = (s['displayNamePublic'] || s['nombre']).to_s.downcase
      dept_patterns.any? { |pattern| name.include?(pattern) }
    end
  end

  def self.department_station_patterns(department)
    patterns = {
      'montevideo' => %w[prado carrasco melilla montevideo],
      'canelones' => %w[canelones atlantida],
      'maldonado' => %w[maldonado punta\ del\ este],
      'colonia' => %w[colonia],
      'salto' => %w[salto],
      'paysandu' => %w[paysandu paysandú],
      'rivera' => %w[rivera],
      'rocha' => %w[rocha],
      'artigas' => %w[artigas],
      'tacuarembo' => %w[tacuarembo tacuarembó],
      'cerro_largo' => %w[melo cerro\ largo],
      'durazno' => %w[durazno],
      'flores' => %w[flores trinidad],
      'florida' => %w[florida],
      'lavalleja' => %w[lavalleja minas],
      'rio_negro' => %w[fray\ bentos rio\ negro young],
      'soriano' => %w[mercedes soriano],
      'san_jose' => %w[san\ jose san\ josé],
      'treinta_y_tres' => %w[treinta]
    }
    patterns[department] || [department]
  end

  def self.build_variable_index(variables)
    index = {}
    variables.each_with_index do |var, i|
      key = VARIABLE_KEYS[var['idStr']]
      index[key] = i if key
    end
    index
  end

  def self.extract_readings(observations, var_index, station_index, time_index)
    readings = {}

    var_index.each do |key, var_idx|
      value = observations.dig(var_idx, 'datos', station_index, time_index)

      if value && key.to_s.include?('knots')
        kmh_key = key.to_s.sub('knots', 'kmh').to_sym
        readings[kmh_key] = (value * KNOTS_TO_KMH).round(1)
      elsif value
        readings[key] = value
      end
    end

    readings
  end

  private_class_method :format_forecast_day, :find_department_stations,
                       :department_station_patterns, :build_variable_index,
                       :extract_readings
end
