require "test_helper"
require "webmock/minitest"

class Api::V1::EconomyControllerTest < ActionDispatch::IntegrationTest
  BPS_HTML = <<~HTML
    <html>
      <body>
        <table>
          <tr><th>Indicador</th><th>Enero</th></tr>
          <tr>
            <td>Base de Prestaciones y Contribuciones (BPC)</td>
            <td class="celda-numero">$ 6.864,00</td>
          </tr>
          <tr>
            <td>Salario mínimo nacional</td>
            <td class="celda-numero">$ 24.572,00</td>
          </tr>
          <tr>
            <td>Unidad Reajustable (UR)</td>
            <td class="celda-numero">$ 1.851,83</td>
          </tr>
          <tr>
            <td>Unidad Indexada</td>
            <td class="celda-numero">$ 6,4401</td>
          </tr>
        </table>
      </body>
    </html>
  HTML

  setup do
    stub_request(:get, EconomyService::BPS_URL).to_return(body: BPS_HTML, status: 200)
  end

  test "returns economy values successfully" do
    get api_v1_economy_values_path

    assert_response :success

    json = JSON.parse(response.body)
    assert_includes json, "bpc"
    assert_includes json, "minimum_wage"
    assert_includes json, "ur"
    assert_includes json, "ui"
  end

  test "values contain expected fields" do
    get api_v1_economy_values_path

    json = JSON.parse(response.body)
    bpc = json["bpc"]

    assert_includes bpc, "value"
    assert_includes bpc, "currency"
    assert_equal "UYU", bpc["currency"]
    assert_in_delta 6864.00, bpc["value"], 0.01
  end

  test "returns error on scraping failure" do
    stub_request(:get, EconomyService::BPS_URL).to_raise(StandardError.new("Connection failed"))

    get api_v1_economy_values_path

    assert_response :internal_server_error

    json = JSON.parse(response.body)
    assert_includes json, "error"
  end
end
