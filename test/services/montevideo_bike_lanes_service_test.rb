require "test_helper"
require "webmock/minitest"

class MontevideoBikeLanesServiceTest < ActiveSupport::TestCase
  GEOJSON = <<~JSON
    {
      "type": "FeatureCollection",
      "totalFeatures": 3,
      "features": [
        {
          "type": "Feature",
          "geometry": { "type": "LineString", "coordinates": [[-56.21, -34.90], [-56.20, -34.89]] },
          "properties": { "gid": 120, "descripcion": "Avenida Cibils - Fase I", "tipo": 3, "ancho": 2.5, "sentido": 2, "activo": 1 }
        },
        {
          "type": "Feature",
          "geometry": { "type": "LineString", "coordinates": [[-56.18, -34.88], [-56.17, -34.87]] },
          "properties": { "gid": 9, "descripcion": "  Bicisenda Rambla  ", "tipo": 1, "ancho": null, "sentido": 0, "activo": 1 }
        },
        {
          "type": "Feature",
          "geometry": { "type": "LineString", "coordinates": [[-56.16, -34.86], [-56.15, -34.85]] },
          "properties": { "gid": 28, "descripcion": "", "tipo": 2, "ancho": 0, "sentido": 1, "activo": 1 }
        }
      ]
    }
  JSON

  setup do
    stub_request(:get, MontevideoBikeLanesService::WFS_URL)
      .with(query: hash_including({ "typeNames" => MontevideoBikeLanesService::TYPE_NAME }))
      .to_return(body: GEOJSON, status: 200)
  end

  test "fetch_bike_lanes returns correct structure" do
    result = MontevideoBikeLanesService.fetch_bike_lanes

    assert_equal "Intendencia de Montevideo", result[:source]
    assert_equal 3, result[:count]
    assert_equal 3, result[:bike_lanes].length
  end

  test "maps tipo codes to labels and slugs" do
    lanes = MontevideoBikeLanesService.fetch_bike_lanes[:bike_lanes]

    assert_equal ["Ciclovía", "Bicisenda", "Calle 30 km/h"], lanes.map { |l| l[:type] }
    assert_equal ["ciclovia", "bicisenda", "calle_30"], lanes.map { |l| l[:type_slug] }
  end

  test "builds a structured lane" do
    lane = MontevideoBikeLanesService.fetch_bike_lanes[:bike_lanes].first

    assert_equal 120, lane[:id]
    assert_equal "Avenida Cibils - Fase I", lane[:name]
    assert_equal 2.5, lane[:width_m]
    assert_equal false, lane[:two_way]
    assert_equal true, lane[:active]
    assert_equal "LineString", lane[:geometry]["type"]
  end

  test "sentido 0 means two_way and strips the name" do
    lane = MontevideoBikeLanesService.fetch_bike_lanes[:bike_lanes][1]

    assert_equal "Bicisenda Rambla", lane[:name]
    assert_equal true, lane[:two_way]
  end

  test "filters by type slug" do
    result = MontevideoBikeLanesService.fetch_bike_lanes(type: "ciclovia")

    assert_equal 1, result[:count]
    assert_equal "Ciclovía", result[:bike_lanes].first[:type]
  end
end
