# Bike circuits service for Montevideo ("Montevideo en Bici").
#
# Fetches the cycling network published by the Intendencia de Montevideo through
# its public GeoServer (WFS). No auth nor JavaScript is required: a plain GET
# asking for GeoJSON returns every active segment with its geometry.
#
# Each segment is one of three types (field `tipo`):
#   1 => Bicisenda     (path on the sidewalk)
#   2 => Calle 30 km/h (shared roadway capped at 30 km/h)
#   3 => Ciclovia      (lane on the roadway with physical separation)
#
# Source: https://montevideo.gub.uy/mapa-montevideo-en-bici
class MontevideoBikeLanesService
  WFS_URL = 'https://montevideo.gub.uy/app/geoserver/wfs'
  TYPE_NAME = 'mapstore-tematicas:vyt_v_bi_bicicircuitos_activos'

  # Maps the numeric `tipo` to its label and a stable English slug used for the
  # `?type=` filter.
  TYPES = {
    1 => { name: 'Bicisenda', slug: 'bicisenda' },
    2 => { name: 'Calle 30 km/h', slug: 'calle_30' },
    3 => { name: 'Ciclovía', slug: 'ciclovia' }
  }.freeze

  # `type` (optional) filters by slug: "ciclovia", "bicisenda" or "calle_30".
  def self.fetch_bike_lanes(type: nil)
    response = HTTParty.get(WFS_URL, query: wfs_params)
    features = parse_features(response.body)
    bike_lanes = features.filter_map { |feature| build_lane(feature) }
    bike_lanes = bike_lanes.select { |lane| lane[:type_slug] == type } if type

    { source: 'Intendencia de Montevideo', count: bike_lanes.length, bike_lanes: }
  end

  def self.wfs_params
    {
      service: 'WFS',
      version: '2.0.0',
      request: 'GetFeature',
      typeNames: TYPE_NAME,
      outputFormat: 'application/json',
      srsName: 'EPSG:4326'
    }
  end

  def self.parse_features(body)
    data = JSON.parse(body)
    data['features'].is_a?(Array) ? data['features'] : []
  rescue JSON::ParserError
    []
  end

  def self.build_lane(feature)
    return nil unless feature.is_a?(Hash)

    properties = feature['properties'] || {}
    type = TYPES[properties['tipo']]
    return nil unless type

    {
      id: properties['gid'],
      name: properties['descripcion'].to_s.strip,
      type: type[:name],
      type_slug: type[:slug],
      width_m: properties['ancho'],
      two_way: properties['sentido'].to_i.zero?,
      active: properties['activo'].to_i == 1,
      geometry: feature['geometry']
    }
  end

  private_class_method :wfs_params, :parse_features, :build_lane
end
