require "test_helper"
require "webmock/minitest"

class UteServiceTest < ActiveSupport::TestCase
  UTE_HTML = <<~HTML
    <html>
      <body>
        <!-- TRS Table -->
        <table>
          <thead style="background-color: #428bca; color: white;">
            <tr><th>Escalones de consumo</th><th>Precio ($/kWh)</th></tr>
          </thead>
          <tbody>
            <tr><td>1° escalón: 1-100 kWh</td><td>6,744</td></tr>
            <tr><td>2° escalón: 101-600 kWh</td><td>8,452</td></tr>
            <tr><td>3° escalón: 601 kWh en adelante</td><td>10,539</td></tr>
          </tbody>
        </table>

        <!-- TRD Table -->
        <table>
          <thead style="background-color: #428bca; color: white;">
            <tr><th>Horarios</th><th>Precio 2026 ($/kWh)*</th></tr>
          </thead>
          <tbody>
            <tr><td>Horario Punta</td><td>$12,034</td></tr>
            <tr><td>Horario Fuera de Punta</td><td>$4,771</td></tr>
          </tbody>
        </table>

        <!-- TRT Table -->
        <table>
          <thead style="background-color: #428bca; color: white;">
            <tr><th>Horarios</th><th>Precio 2026 ($/kWh)*</th></tr>
          </thead>
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

  # --- TRS ---

  test "parses TRS tiers" do
    result = UteService.fetch_tariffs

    assert result[:trs]
    assert_equal "simple", result[:trs][:type]
    assert_equal 3, result[:trs][:tiers].length
  end

  test "TRS tier 1 price is correct" do
    result = UteService.fetch_tariffs
    tier1 = result[:trs][:tiers][0]

    assert_equal "1-100 kWh", tier1[:tier]
    assert_in_delta 6.744, tier1[:price_per_kwh], 0.001
  end

  test "TRS tier 2 price is correct" do
    result = UteService.fetch_tariffs
    tier2 = result[:trs][:tiers][1]

    assert_equal "101-600 kWh", tier2[:tier]
    assert_in_delta 8.452, tier2[:price_per_kwh], 0.001
  end

  test "TRS tier 3 price is correct" do
    result = UteService.fetch_tariffs
    tier3 = result[:trs][:tiers][2]

    assert_equal "601+ kWh", tier3[:tier]
    assert_in_delta 10.539, tier3[:price_per_kwh], 0.001
  end

  # --- TRD ---

  test "parses TRD periods" do
    result = UteService.fetch_tariffs

    assert result[:trd]
    assert_equal "doble_horario", result[:trd][:type]
    assert_equal 2, result[:trd][:periods].length
  end

  test "TRD punta price is correct" do
    result = UteService.fetch_tariffs
    punta = result[:trd][:periods].find { |p| p[:period] == 'punta' }

    assert_in_delta 12.034, punta[:price_per_kwh], 0.001
  end

  test "TRD fuera de punta price is correct" do
    result = UteService.fetch_tariffs
    off_peak = result[:trd][:periods].find { |p| p[:period] == 'fuera de punta' }

    assert_in_delta 4.771, off_peak[:price_per_kwh], 0.001
  end

  # --- TRT ---

  test "parses TRT periods" do
    result = UteService.fetch_tariffs

    assert result[:trt]
    assert_equal "triple_horario", result[:trt][:type]
    assert_equal 3, result[:trt][:periods].length
  end

  test "TRT valle price is correct" do
    result = UteService.fetch_tariffs
    valle = result[:trt][:periods].find { |p| p[:period] == 'valle' }

    assert_in_delta 2.443, valle[:price_per_kwh], 0.001
  end

  test "TRT llano price is correct" do
    result = UteService.fetch_tariffs
    llano = result[:trt][:periods].find { |p| p[:period] == 'llano' }

    assert_in_delta 5.172, llano[:price_per_kwh], 0.001
  end

  # --- General ---

  test "returns currency" do
    result = UteService.fetch_tariffs

    assert_equal "UYU", result[:currency]
  end

  test "returns VAT rate" do
    result = UteService.fetch_tariffs

    assert_in_delta 0.22, result[:vat_rate], 0.001
  end

  test "returns note about VAT" do
    result = UteService.fetch_tariffs

    assert_includes result[:note], "IVA"
  end

  test "returns empty hash when no tables found" do
    stub_request(:get, UteService::TARIFFS_URL)
      .to_return(body: "<html><body></body></html>", status: 200)

    result = UteService.fetch_tariffs

    assert_equal({}, result)
  end
end
