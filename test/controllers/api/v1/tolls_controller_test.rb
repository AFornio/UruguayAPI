require "test_helper"
require "webmock/minitest"

class Api::V1::TollsControllerTest < ActionDispatch::IntegrationTest
  RATES_HTML = <<~HTML
    <html>
      <body>
        <table>
          <tr><th>Categoría</th><th>Básica</th><th>Telepeaje</th><th>SUCIVE</th></tr>
          <tr><td>Categoría 1</td><td>$ 120</td><td>$ 100</td><td>$ 90</td></tr>
        </table>
      </body>
    </html>
  HTML

  LOCATIONS_HTML = <<~HTML
    <html>
      <body>
        <ul>
          <li><strong>Ruta 1:</strong> Barra de Santa Lucía (km 23,5)</li>
        </ul>
      </body>
    </html>
  HTML

  setup do
    stub_request(:get, TollsService::RATES_URL).to_return(body: RATES_HTML, status: 200)
    stub_request(:get, TollsService::LOCATIONS_URL).to_return(body: LOCATIONS_HTML, status: 200)
  end

  test "returns toll prices successfully" do
    get api_v1_tolls_prices_path

    assert_response :success

    json = JSON.parse(response.body)
    assert_includes json, "rates"
    assert_includes json, "locations"
    assert_equal "UYU", json["currency"]
  end

  test "rates contain expected fields" do
    get api_v1_tolls_prices_path

    json = JSON.parse(response.body)
    rate = json["rates"].first

    assert_includes rate, "category"
    assert_includes rate, "basic"
    assert_includes rate, "telepeaje"
    assert_includes rate, "sucive"
  end

  test "locations contain expected fields" do
    get api_v1_tolls_prices_path

    json = JSON.parse(response.body)
    location = json["locations"].first

    assert_includes location, "name"
    assert_includes location, "route"
    assert_includes location, "km"
  end

  test "returns error on scraping failure" do
    stub_request(:get, TollsService::RATES_URL).to_raise(StandardError.new("Connection failed"))

    get api_v1_tolls_prices_path

    assert_response :internal_server_error

    json = JSON.parse(response.body)
    assert_includes json, "error"
  end
end
