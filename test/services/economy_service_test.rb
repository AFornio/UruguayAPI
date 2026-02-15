require "test_helper"
require "webmock/minitest"

class EconomyServiceTest < ActiveSupport::TestCase
  BPS_HTML = <<~HTML
    <html>
      <body>
        <table>
          <tr>
            <th>Indicador</th>
            <th>Enero</th>
            <th>Febrero</th>
          </tr>
          <tr>
            <td> Base Ficta de Contribución (BFC) <sup>(1)</sup></td>
            <td class="celda-numero">$ 1.847,96</td>
            <td class="celda-numero">$ 1.847,96</td>
          </tr>
          <tr>
            <td> Base de Prestaciones y Contribuciones (BPC) <sup>(1)</sup></td>
            <td class="celda-numero">$ 6.864,00</td>
            <td class="celda-numero">$ 6.864,00</td>
          </tr>
          <tr>
            <td> Salario mínimo nacional <sup>(1)</sup></td>
            <td class="celda-numero">$ 24.572,00</td>
            <td class="celda-numero">$ 24.572,00</td>
          </tr>
          <tr>
            <td> Salario mínimo Servicio Doméstico <sup>(1)</sup></td>
            <td class="celda-numero">$ 31.178,00</td>
            <td class="celda-numero">$ 31.178,00</td>
          </tr>
          <tr>
            <td> Cuota mutual <sup>(1)</sup></td>
            <td class="celda-numero">$ 1.820,00</td>
            <td class="celda-numero">$ 1.820,00</td>
          </tr>
          <tr>
            <td> Costo Promedio Equivalente (CPE) <sup>(1)</sup></td>
            <td class="celda-numero">$ 6.693,00</td>
            <td class="celda-numero">$ 6.693,00</td>
          </tr>
          <tr>
            <td> Unidad Reajustable (UR) <sup>(4)</sup></td>
            <td class="celda-numero">$ 1.847,96</td>
            <td class="celda-numero">$ 1.851,83</td>
          </tr>
          <tr>
            <td> Recargo por mora (mensual capitalizable cuatrimestralmente)</td>
            <td class="celda-numero">0,90 %</td>
            <td class="celda-numero">0,90 %</td>
          </tr>
          <tr>
            <td> Unidad Indexada</td>
            <td class="celda-numero">$ 6,4401</td>
          </tr>
        </table>
      </body>
    </html>
  HTML

  setup do
    stub_request(:get, EconomyService::BPS_URL).to_return(body: BPS_HTML, status: 200)
  end

  test "returns correct structure with all indicators" do
    result = EconomyService.fetch_values

    assert_includes result, :bpc
    assert_includes result, :ur
    assert_includes result, :ui
    assert_includes result, :minimum_wage
    assert_includes result, :domestic_minimum_wage
    assert_includes result, :mutual_quota
    assert_includes result, :cpe
    assert_includes result, :bfc
  end

  test "each indicator has value and currency" do
    result = EconomyService.fetch_values

    result.each do |key, data|
      assert_includes data, :value, "#{key} missing :value"
      assert_includes data, :currency, "#{key} missing :currency"
      assert_equal "UYU", data[:currency]
    end
  end

  test "parses BPC correctly" do
    result = EconomyService.fetch_values

    assert_in_delta 6864.00, result[:bpc][:value], 0.01
  end

  test "parses UR correctly" do
    result = EconomyService.fetch_values

    assert_in_delta 1851.83, result[:ur][:value], 0.01
  end

  test "parses UI correctly" do
    result = EconomyService.fetch_values

    assert_in_delta 6.4401, result[:ui][:value], 0.0001
  end

  test "parses minimum wage correctly" do
    result = EconomyService.fetch_values

    assert_in_delta 24_572.00, result[:minimum_wage][:value], 0.01
  end

  test "picks latest column value" do
    # UR tiene valores distintos en Enero y Febrero, debe tomar Febrero
    result = EconomyService.fetch_values

    assert_in_delta 1851.83, result[:ur][:value], 0.01
  end

  test "handles single column value" do
    # UI solo tiene valor en Enero (una sola columna)
    result = EconomyService.fetch_values

    assert_in_delta 6.4401, result[:ui][:value], 0.0001
  end

  test "skips non-mapped indicators" do
    result = EconomyService.fetch_values

    # "Recargo por mora" no está mapeado
    keys = result.keys
    refute_includes keys, :recargo_mora
  end

  test "returns empty hash when no table found" do
    stub_request(:get, EconomyService::BPS_URL)
      .to_return(body: "<html><body></body></html>", status: 200)

    result = EconomyService.fetch_values

    assert_equal({}, result)
  end
end
