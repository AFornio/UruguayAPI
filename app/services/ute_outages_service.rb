# Power outages service for UTE (scheduled improvement works).
#
# Consumes the same internal JSON API that powers UTE's public service-status
# map (no auth required). Unlike the OSE source, this one includes coordinates
# and the number of affected clients per work.
#
# Source: https://apps2.ute.com.uy/SioServEcse
# (map at portal.ute.com.uy/.../mapa-interactivo-de-la-situacion-del-servicio-electrico)
class UteOutagesService
  WORKS_URL = 'https://apps2.ute.com.uy/SioServEcse/api/Ecse/ObtenerTrabajosMejora'

  def self.fetch_outages
    response = HTTParty.get(WORKS_URL)
    works = parse_body(response.body)
    outages = works.filter_map { |work| build_outage(work) }

    { source: 'UTE', count: outages.length, outages: }
  end

  def self.parse_body(body)
    data = JSON.parse(body)
    data.is_a?(Array) ? data : []
  rescue JSON::ParserError
    []
  end

  def self.build_outage(work)
    return nil unless work.is_a?(Hash)

    latitude, longitude = parse_coordinates(work['COORDENADAS'])

    {
      id: work['ID_INCIDENCIA'],
      installation: work['INSTALACION_AFECTADA'].to_s.strip,
      latitude:,
      longitude:,
      affected_clients: work['CLIENTES_AFECTADOS'],
      clients_to_restore: work['CLIENTES_A_REPONER'],
      detected_at: work['FECHA_DETECCION'].to_s.strip,
      estimated_restoration: work['FECHA_PREVISTA_REPOSICION'].to_s.strip,
      scheduled: work['PROGRAMADA'] == true
    }
  end

  # COORDENADAS comes as "lng,lat lng,lat ..."; takes the first pair.
  # Returns [latitude, longitude], or [nil, nil] when it can't be parsed.
  def self.parse_coordinates(raw)
    return [nil, nil] if raw.nil? || raw.to_s.strip.empty?

    first = raw.to_s.strip.split(' ').first
    longitude, latitude = first.split(',').map { |value| Float(value, exception: false) }
    return [nil, nil] if latitude.nil? || longitude.nil?

    [latitude, longitude]
  end

  private_class_method :parse_body, :build_outage, :parse_coordinates
end
