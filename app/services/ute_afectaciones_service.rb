# Real-time power outage service for UTE, broken down by zone.
#
# Two endpoints from the same internal API used by the ECSE interactive map:
#   - ObtenerAfectacionesZona: aggregated stats per department (or commercial office)
#   - ObtenerAfectacionesUrbanas: stats per urban neighborhood
#
# Both return current interruptions (intempestivas) and scheduled ones (programadas).
# No auth required.
#
# Source: https://apps2.ute.com.uy/SioServEcse
class UteAfectacionesService
  BASE_URL = 'https://apps2.ute.com.uy/SioServEcse/api/Ecse'
  DEPARTMENTS_URL = "#{BASE_URL}/ObtenerAfectacionesZona?strZona=Departamento"
  NEIGHBORHOODS_URL = "#{BASE_URL}/ObtenerAfectacionesUrbanas"

  def self.fetch_all
    departments = fetch_json(DEPARTMENTS_URL).filter_map { |zone| build_zone(zone) }
    neighborhoods = fetch_json(NEIGHBORHOODS_URL).filter_map { |zone| build_zone(zone) }

    {
      departments: { count: departments.length, items: departments },
      neighborhoods: { count: neighborhoods.length, items: neighborhoods }
    }
  end

  def self.fetch_json(url)
    response = HTTParty.get(url)
    data = JSON.parse(response.body)
    data.is_a?(Array) ? data : []
  rescue JSON::ParserError
    []
  end

  def self.build_zone(zone)
    return nil unless zone.is_a?(Hash)

    {
      id: zone['ID_ZONA'],
      name: zone['NOMBRE_ZONA'].to_s.strip,
      zone_type: zone['TIPO_ZONA'].to_s.strip,
      latitude: zone['LATITUD'],
      longitude: zone['LONGITUD'],
      pending_notices: zone['AVISOS_PENDIENTES'],
      unplanned_affected: zone['AFECTADOS_INTEMPESTIVOS'],
      planned_affected: zone['AFECTADOS_PROGRAMADOS'],
      incidents: zone['INCIDENCIAS_EN_ZONA'],
      planned_incidents: zone['INCID_PROGRAMADAS_EN_ZONA'],
      clients_interrupted: zone['CLIENTES_INTERRUMPIDOS'],
      total_clients: zone['TOTAL_CLIENTES_DE_ZONA'],
      affected_percentage: zone['PORCENTAJE_DE_AFECTADOS'],
      updated_at: zone['FECHA'].to_s.strip
    }
  end

  private_class_method :fetch_json, :build_zone
end
