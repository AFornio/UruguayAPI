require "test_helper"
require "webmock/minitest"

class UteOutagesServiceTest < ActiveSupport::TestCase
  WORKS_JSON = <<~JSON
    [
      {
        "FECHA_DETECCION": "3/6/2026 9:00:00",
        "ID_INCIDENCIA": 8600832,
        "INSTALACION_AFECTADA": "SB 1340",
        "COORDENADAS": "-56.2570866259,-34.8292420904 -56.2570866259,-34.8292420904",
        "CLIENTES_AFECTADOS": 2,
        "CLIENTES_A_REPONER": 2,
        "FECHA_PREVISTA_REPOSICION": "3/6/2026 17:00:00",
        "PROGRAMADA": true
      },
      {
        "FECHA_DETECCION": "3/6/2026 7:22:36",
        "ID_INCIDENCIA": 8562066,
        "INSTALACION_AFECTADA": "SAL 2014",
        "COORDENADAS": "-57.9033024407,-31.9336074755",
        "CLIENTES_AFECTADOS": 16,
        "CLIENTES_A_REPONER": 16,
        "FECHA_PREVISTA_REPOSICION": "3/6/2026 17:30:00",
        "PROGRAMADA": false
      }
    ]
  JSON

  setup do
    stub_request(:get, UteOutagesService::WORKS_URL).to_return(body: WORKS_JSON, status: 200)
  end

  test "fetch_outages returns correct structure" do
    result = UteOutagesService.fetch_outages

    assert_equal "UTE", result[:source]
    assert_equal 2, result[:count]
    assert_equal 2, result[:outages].length
  end

  test "parses coordinates as [latitude, longitude]" do
    outage = UteOutagesService.fetch_outages[:outages].first

    assert_in_delta(-34.8292420904, outage[:latitude], 0.0001)
    assert_in_delta(-56.2570866259, outage[:longitude], 0.0001)
  end

  test "maps installation, clients and dates" do
    outage = UteOutagesService.fetch_outages[:outages].first

    assert_equal "SB 1340", outage[:installation]
    assert_equal 2, outage[:affected_clients]
    assert_equal 2, outage[:clients_to_restore]
    assert_equal "3/6/2026 9:00:00", outage[:detected_at]
    assert_equal "3/6/2026 17:00:00", outage[:estimated_restoration]
    assert_equal true, outage[:scheduled]
  end

  test "returns empty list when body is not a JSON array" do
    stub_request(:get, UteOutagesService::WORKS_URL).to_return(body: "not json", status: 200)

    result = UteOutagesService.fetch_outages

    assert_equal 0, result[:count]
    assert_equal [], result[:outages]
  end

  test "tolerates missing coordinates" do
    body = '[{"ID_INCIDENCIA":1,"INSTALACION_AFECTADA":"X","COORDENADAS":""}]'
    stub_request(:get, UteOutagesService::WORKS_URL).to_return(body: body, status: 200)

    outage = UteOutagesService.fetch_outages[:outages].first

    assert_nil outage[:latitude]
    assert_nil outage[:longitude]
  end
end
