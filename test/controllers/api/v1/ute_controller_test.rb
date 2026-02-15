require "test_helper"
require "webmock/minitest"

class Api::V1::UteControllerTest < ActionDispatch::IntegrationTest
  UTE_HTML = <<~HTML
    <html>
      <body>
        <table>
          <thead><tr><th>Escalones de consumo</th><th>Precio ($/kWh)</th></tr></thead>
          <tbody>
            <tr><td>1° escalón: 1-100 kWh</td><td>6,744</td></tr>
            <tr><td>2° escalón: 101-600 kWh</td><td>8,452</td></tr>
            <tr><td>3° escalón: 601 kWh en adelante</td><td>10,539</td></tr>
          </tbody>
        </table>
        <table>
          <thead><tr><th>Horarios</th><th>Precio ($/kWh)</th></tr></thead>
          <tbody>
            <tr><td>Horario Punta</td><td>$12,034</td></tr>
            <tr><td>Horario Fuera de Punta</td><td>$4,771</td></tr>
          </tbody>
        </table>
        <table>
          <thead><tr><th>Horarios</th><th>Precio ($/kWh)</th></tr></thead>
          <tbody>
            <tr><td>Horario Punta</td><td>$12,034</td></tr>
            <tr><td>Horario Valle</td><td>$2,443</td></tr>
            <tr><td>Horario Llano</td><td>$5,172</td></tr>
          </tbody>
        </table>
      </body>
    </html>
  HTML

  setup do
    stub_request(:get, UteService::TARIFFS_URL).to_return(body: UTE_HTML, status: 200)
  end

  test "returns tariffs successfully" do
    get api_v1_ute_tariffs_path

    assert_response :success

    json = JSON.parse(response.body)
    assert json["trs"]
    assert json["trd"]
    assert json["trt"]
    assert_equal "UYU", json["currency"]
  end

  test "TRS has 3 tiers" do
    get api_v1_ute_tariffs_path

    json = JSON.parse(response.body)

    assert_equal 3, json["trs"]["tiers"].length
  end

  test "TRD has 2 periods" do
    get api_v1_ute_tariffs_path

    json = JSON.parse(response.body)

    assert_equal 2, json["trd"]["periods"].length
  end

  test "TRT has 3 periods" do
    get api_v1_ute_tariffs_path

    json = JSON.parse(response.body)

    assert_equal 3, json["trt"]["periods"].length
  end

  test "handles scraping failure" do
    stub_request(:get, UteService::TARIFFS_URL).to_raise(StandardError.new("Connection failed"))

    get api_v1_ute_tariffs_path

    assert_response :internal_server_error

    json = JSON.parse(response.body)
    assert_includes json, "error"
  end
end
