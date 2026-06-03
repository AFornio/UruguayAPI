require "test_helper"
require "webmock/minitest"

class Api::V1::OseControllerTest < ActionDispatch::IntegrationTest
  ROWS = [
    [
      "AFECTACIÓN DEL NORMAL SUMINISTRO DE AGUA POTABLE",
      "Fecha de publicación: 03/06/2026 - Hora: 12:46",
      "Localidad MONTEVIDEO, Departamento de MONTEVIDEO",
      "Zona afectada:", "Barrio Tres Ombúes",
      "Desde:", "4 de junio hora 09:00",
      "Hasta:", "4 de junio hora 15:00",
      "Motivo:", "trabajos programados",
      "Información adicional:", ""
    ]
  ].freeze

  HTML = <<~BODY
    <html><body>
      <input type="hidden" name="W0006GridContainerDataV" value='#{ROWS.to_json}' />
    </body></html>
  BODY

  setup do
    stub_request(:get, OseService::OUTAGES_URL).to_return(body: HTML, status: 200)
  end

  test "returns water outages successfully" do
    get api_v1_ose_outages_path

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "OSE", json["source"]
    assert_equal 1, json["count"]
  end

  test "outages contain expected fields" do
    get api_v1_ose_outages_path

    json = JSON.parse(response.body)
    outage = json["outages"].first

    assert_includes outage, "department"
    assert_includes outage, "locality"
    assert_includes outage, "affected_area"
    assert_includes outage, "starts_at"
    assert_includes outage, "ends_at"
    assert_includes outage, "reason"
  end

  test "returns error on scraping failure" do
    stub_request(:get, OseService::OUTAGES_URL).to_raise(StandardError.new("Connection failed"))

    get api_v1_ose_outages_path

    assert_response :internal_server_error

    json = JSON.parse(response.body)
    assert_includes json, "error"
  end
end
