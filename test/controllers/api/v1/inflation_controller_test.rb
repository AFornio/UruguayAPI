require "test_helper"
require "webmock/minitest"

class Api::V1::InflationControllerTest < ActionDispatch::IntegrationTest
  INE_HTML = <<~HTML
    <html>
      <body>
        <a href="#">Índice de Precios del Consumo (Var.12 meses) 01/26: 3,46%</a>
        <a href="#">Índice Medio de Salarios (Var.12 meses) 12/25: 5,99%</a>
      </body>
    </html>
  HTML

  setup do
    stub_request(:get, InflationService::INE_URL).to_return(body: INE_HTML, status: 200)
  end

  test "returns inflation indicators successfully" do
    get api_v1_inflation_indicators_path

    assert_response :success

    json = JSON.parse(response.body)
    assert_includes json, "ipc"
    assert_includes json, "ims"
  end

  test "indicators contain expected fields" do
    get api_v1_inflation_indicators_path

    json = JSON.parse(response.body)
    ipc = json["ipc"]

    assert_includes ipc, "period"
    assert_includes ipc, "variation_12m"
    assert_equal "01/26", ipc["period"]
  end

  test "returns error on scraping failure" do
    stub_request(:get, InflationService::INE_URL).to_raise(StandardError.new("Connection failed"))

    get api_v1_inflation_indicators_path

    assert_response :internal_server_error

    json = JSON.parse(response.body)
    assert_includes json, "error"
  end
end
