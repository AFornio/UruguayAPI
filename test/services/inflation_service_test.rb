require "test_helper"
require "webmock/minitest"

class InflationServiceTest < ActiveSupport::TestCase
  INE_HTML = <<~HTML
    <html>
      <body>
        <div>
          <a href="https://www5.ine.gub.uy/documents/IPC.xlsx">Índice de Precios del Consumo (Var.12 meses) 01/26: 3,46%</a>
          <a href="https://www5.ine.gub.uy/documents/IMS.xls">Índice Medio de Salarios (Var.12 meses) 12/25: 5,99%</a>
          <a href="https://www5.ine.gub.uy/documents/IMSN.xls">Indice Medio de Salarios Nominales (Var. 12 meses) 12/25: 5,97%</a>
          <a href="https://www5.ine.gub.uy/documents/ICCV.xlsx">Índice de Costo de la Construcción de Viviendas (Var. 12 meses) 12/25: 3,66%</a>
          <a href="/other">Link sin indicador</a>
        </div>
      </body>
    </html>
  HTML

  setup do
    stub_request(:get, InflationService::INE_URL).to_return(body: INE_HTML, status: 200)
  end

  test "returns all four indicators" do
    result = InflationService.fetch_indicators

    assert_includes result, :ipc
    assert_includes result, :ims
    assert_includes result, :imsn
    assert_includes result, :iccv
  end

  test "parses IPC correctly" do
    result = InflationService.fetch_indicators

    assert_equal "01/26", result[:ipc][:period]
    assert_in_delta 3.46, result[:ipc][:variation_12m], 0.01
  end

  test "parses IMS correctly" do
    result = InflationService.fetch_indicators

    assert_equal "12/25", result[:ims][:period]
    assert_in_delta 5.99, result[:ims][:variation_12m], 0.01
  end

  test "parses IMSN correctly" do
    result = InflationService.fetch_indicators

    assert_equal "12/25", result[:imsn][:period]
    assert_in_delta 5.97, result[:imsn][:variation_12m], 0.01
  end

  test "parses ICCV correctly" do
    result = InflationService.fetch_indicators

    assert_equal "12/25", result[:iccv][:period]
    assert_in_delta 3.66, result[:iccv][:variation_12m], 0.01
  end

  test "each indicator has period and variation" do
    result = InflationService.fetch_indicators

    result.each do |key, data|
      assert_includes data, :period, "#{key} missing :period"
      assert_includes data, :variation_12m, "#{key} missing :variation_12m"
    end
  end

  test "returns empty hash when no indicators found" do
    stub_request(:get, InflationService::INE_URL)
      .to_return(body: "<html><body><a href='/'>Home</a></body></html>", status: 200)

    result = InflationService.fetch_indicators

    assert_equal({}, result)
  end
end
