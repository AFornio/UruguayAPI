require "test_helper"
require "webmock/minitest"

class TollsServiceTest < ActiveSupport::TestCase
  RATES_HTML = <<~HTML
    <html>
      <body>
        <table>
          <tr>
            <th>Categoría</th>
            <th>Tarifa BÁSICA</th>
            <th>Telepeaje</th>
            <th>SUCIVE</th>
          </tr>
          <tr>
            <td>Categoría 1 - Autos y camionetas</td>
            <td>$ 120</td>
            <td>$ 100</td>
            <td>$ 90</td>
          </tr>
          <tr>
            <td>Categoría 2 - Ómnibus hasta 25 pasajeros</td>
            <td>$ 240</td>
            <td>$ 200</td>
            <td>$ 180</td>
          </tr>
        </table>
      </body>
    </html>
  HTML

  LOCATIONS_HTML = <<~HTML
    <html>
      <body>
        <ul>
          <li><strong>Ruta 1:</strong> Barra de Santa Lucía (km 23,5) y Cufré (km 107,3)</li>
          <li><strong>Ruta 5:</strong> Mendoza (km 67,7), Centenario (km 246,3) y Manuel Díaz (km 423,2)</li>
          <li><strong>Interbalnearia:</strong> Pando (km 32,4) y Solís (km 81)</li>
        </ul>
      </body>
    </html>
  HTML

  setup do
    stub_request(:get, TollsService::RATES_URL).to_return(body: RATES_HTML, status: 200)
    stub_request(:get, TollsService::LOCATIONS_URL).to_return(body: LOCATIONS_HTML, status: 200)
  end

  test "fetch_all returns correct structure" do
    result = TollsService.fetch_all

    assert_includes result, :rates
    assert_includes result, :locations
    assert_includes result, :currency
    assert_equal "UYU", result[:currency]
  end

  test "parses rates correctly" do
    result = TollsService.fetch_all

    assert_equal 2, result[:rates].length

    first = result[:rates].first
    assert_includes first[:category], "Categoría 1"
    assert_equal "$ 120", first[:basic]
    assert_equal "$ 100", first[:telepeaje]
    assert_equal "$ 90", first[:sucive]
  end

  test "parses locations correctly" do
    result = TollsService.fetch_all

    locations = result[:locations]
    assert_equal 7, locations.length

    barra = locations.find { |l| l[:name] == "Barra de Santa Lucía" }
    assert_not_nil barra
    assert_equal "Ruta 1", barra[:route]
    assert_equal "23.5", barra[:km]
  end

  test "parses multiple locations per route" do
    result = TollsService.fetch_all

    ruta5_locations = result[:locations].select { |l| l[:route] == "Ruta 5" }
    assert_equal 3, ruta5_locations.length

    names = ruta5_locations.map { |l| l[:name] }
    assert_includes names, "Mendoza"
    assert_includes names, "Centenario"
    assert_includes names, "Manuel Díaz"
  end

  test "returns empty rates when no table found" do
    stub_request(:get, TollsService::RATES_URL).to_return(body: "<html><body></body></html>", status: 200)

    result = TollsService.fetch_all

    assert_equal [], result[:rates]
  end

  test "returns empty locations when no list found" do
    stub_request(:get, TollsService::LOCATIONS_URL).to_return(body: "<html><body></body></html>", status: 200)

    result = TollsService.fetch_all

    assert_equal [], result[:locations]
  end
end
