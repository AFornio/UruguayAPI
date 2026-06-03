require "test_helper"
require "webmock/minitest"

class OseServiceTest < ActiveSupport::TestCase
  ROWS = [
    [
      "AFECTACIÓN DEL NORMAL SUMINISTRO DE AGUA POTABLE",
      "Fecha de publicación: 03/06/2026 - Hora:         12:46",
      "Localidad MONTEVIDEO, Departamento de MONTEVIDEO",
      "Zona afectada:", "", "Barrio Tres Ombúes, en calles Av. Luis Batlle Berres",
      "Desde:", "", "4 de junio hora         09:00",
      "Hasta:", "", "4 de junio hora         15:00",
      "Motivo:", "", "trabajos programados de sustitución de tuberías",
      "Información adicional:", "", "Podría salir turbia al restablecer"
    ],
    [
      "AFECTACIÓN DEL NORMAL SUMINISTRO DE AGUA POTABLE",
      "Fecha de publicación: 03/06/2026 - Hora: 10:02",
      "Localidad JOSE IGNACIO, Departamento de MALDONADO",
      "Zona afectada:", "Balneario José Ignacio",
      "Desde:", "4 de junio hora 08:00",
      "Hasta:", "4 de junio hora 12:00",
      "Motivo:", "Trabajos programados de mejoras en la red de distribución",
      "Información adicional:", ""
    ]
  ].freeze

  def html_with(rows)
    <<~HTML
      <html><body>
        <input type="hidden" name="W0006GridContainerDataV" value='#{rows.to_json}' />
      </body></html>
    HTML
  end

  setup do
    stub_request(:get, OseService::OUTAGES_URL).to_return(body: html_with(ROWS), status: 200)
  end

  test "fetch_outages returns correct structure" do
    result = OseService.fetch_outages

    assert_equal "OSE", result[:source]
    assert_equal 2, result[:count]
    assert_equal 2, result[:outages].length
  end

  test "parses location into department and locality" do
    outage = OseService.fetch_outages[:outages].first

    assert_equal "MONTEVIDEO", outage[:department]
    assert_equal "MONTEVIDEO", outage[:locality]
  end

  test "parses a different department and locality" do
    outage = OseService.fetch_outages[:outages].last

    assert_equal "MALDONADO", outage[:department]
    assert_equal "JOSE IGNACIO", outage[:locality]
  end

  test "extracts schedule, area and reason cleaning whitespace" do
    outage = OseService.fetch_outages[:outages].first

    assert_equal "4 de junio hora 09:00", outage[:starts_at]
    assert_equal "4 de junio hora 15:00", outage[:ends_at]
    assert_includes outage[:affected_area], "Barrio Tres Ombúes"
    assert_includes outage[:reason], "sustitución de tuberías"
  end

  test "extracts published date and time" do
    outage = OseService.fetch_outages[:outages].first

    assert_equal "03/06/2026 12:46", outage[:published_at]
  end

  test "returns empty list when grid input is missing" do
    stub_request(:get, OseService::OUTAGES_URL).to_return(body: "<html><body></body></html>", status: 200)

    result = OseService.fetch_outages

    assert_equal 0, result[:count]
    assert_equal [], result[:outages]
  end
end
