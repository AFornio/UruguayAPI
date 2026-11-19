# Estado de las playas de Montevideo: bandera de guardavidas, alerta sanitaria, UV y temperatura.
#
# Fuente: la API JSON del mapa "Estado de las playas en tiempo real" de la Intendencia
# (https://pci.montevideo.gub.uy/playas/). Cada playa tiene una o más casillas de guardavidas;
# por playa se muestra la bandera más restrictiva y la alerta sanitaria vigente.
class BeachesService
  BASE_URL = 'https://pci.montevideo.gub.uy/playas/api'.freeze
  PAGE = 'https://montevideo.gub.uy/playas'.freeze
  # De menos a más restrictiva: verde (mar calmo), amarilla (precaución), roja (prohibido bañarse).
  FLAGS = %w[green yellow red].freeze

  class << self
    def fetch_all(now: Time.current)
      beaches, stations, weather = %w[playas casillas clima].map { |endpoint| json(endpoint) }
      by_beach = stations.fetch('features').pluck('properties').group_by { |station| station['beach'] }

      {
        beaches: beaches.map { |beach| beach_status(beach, by_beach.fetch(beach['id'], []), now) },
        uv: weather.dig('ValorIndiceUV', 'value'),
        temperature: weather.dig('TemepraturaActual', 'value'),
        max_temperature: weather.dig('TemperaturaMaxMin', 'tempMax'),
        min_temperature: weather.dig('TemperaturaMaxMin', 'tempMin'),
        url: PAGE
      }
    end

    private

    def json(endpoint)
      JSON.parse(Scraper.get("#{BASE_URL}/#{endpoint}").body)
    end

    def beach_status(beach, stations, now)
      {
        id: beach['id'],
        name: beach['name'],
        url: beach['link'],
        location: beach['location'],
        stations: stations.size,
        safety_flag: safety_flag(stations, now),
        health_warning: health_warning(stations, now)
      }
    end

    # La más restrictiva entre las casillas con bandera vigente; nil si ninguna tiene.
    def safety_flag(stations, now)
      flags = stations.select { |station| current?(station['safetyFlagExpiration'], now) }.pluck('safetyFlag')
      flags.select { |flag| FLAGS.include?(flag) }.max_by { |flag| FLAGS.index(flag) }
    end

    # healthFlag "true" = no se recomienda bañarse (lluvias, cianobacterias, etc.).
    def health_warning(stations, now)
      station = stations.find do |s|
        s['healthFlag'].to_s == 'true' && current?(s['healthFlagExpiration'], now)
      end
      return if station.nil?

      { cause: station['healthFlagCauseDesc'].presence, detail: station['healthFlagCauseLongDesc'].presence,
        until: station['healthFlagExpiration'] }
    end

    def current?(expiration, now)
      expiration.present? && Time.zone.parse(expiration) > now
    rescue ArgumentError
      false
    end
  end
end
