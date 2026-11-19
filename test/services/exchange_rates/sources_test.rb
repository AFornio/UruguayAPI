require 'test_helper'
require 'webmock/minitest'

# Un test por fuente, con el markup real de cada sitio reducido a lo mínimo.
class ExchangeRates::SourcesTest < ActiveSupport::TestCase
  BROU_HTML = <<~HTML.freeze
    <table>
      <tr><td><p class="moneda">Dólar</p></td><td></td><td><p class="valor"> 39,40000 </p></td>
          <td></td><td><p class="valor">41,80000</p></td></tr>
      <tr><td><p class="moneda">Dólar eBROU</p></td><td></td><td><p class="valor">39,90000</p></td>
          <td></td><td><p class="valor">41,30000</p></td></tr>
    </table>
  HTML

  ITAU_XML = <<~XML.freeze
    <root>
      <cotizacion><moneda>US.D</moneda><compra>39,30</compra><venta>41,90</venta></cotizacion>
      <cotizacion><moneda>EUR </moneda><compra>42,45</compra><venta>46,90</venta></cotizacion>
      <cotizacion><moneda>LINK</moneda><compra>39,60</compra><venta>41,60</venta></cotizacion>
    </root>
  XML

  CAMBILEX_HTML = <<~HTML.freeze
    <div class="cc-grid-widget-row"><span>Dólar</span> <span>39,40</span> <span>41,80</span></div>
    <div class="cc-grid-widget-row"><span>Dólar finza</span> <span>40,05</span> <span>40,95</span></div>
  HTML

  # Wix: cada celda en su div, sin espacios entre una y otra.
  CAMBIO18_HTML = '<table><tr><td><div></div></td><td><div>DÓLAR</div></td>' \
                  '<td><div>39.40</div></td><td><div>41.80</div></td></tr></table>'.freeze

  AEROMAR_HTML = <<~HTML.freeze
    <div class="mod-cotizacion">
      <div class="col-xs-4 text-center"><p class="title">Compra</p><p class="cot-value">39.40</p><p class="cot-value">0.02</p></div>
      <div class="col-xs-4 text-center"><p class="title">Venta</p><p class="cot-value">41.80</p><p class="cot-value">0.20</p></div>
    </div>
  HTML

  def rates(source)
    ExchangeRates.fetch(source).map { |rate| rate.values_at(:name, :kind, :buy, :sell) }
  end

  test 'brou: pizarra y eBROU' do
    stub_request(:get, ExchangeRates::Brou::URL).to_return(body: BROU_HTML)

    assert_equal [['BROU', 'counter', 39.4, 41.8], ['eBROU', 'online', 39.9, 41.3]], rates('brou')
  end

  test 'itau: pizarra y Link del XML' do
    stub_request(:get, ExchangeRates::Itau::URL).to_return(body: ITAU_XML)

    assert_equal [['Itaú', 'counter', 39.3, 41.9], ['Itaú Link', 'online', 39.6, 41.6]], rates('itau')
  end

  test 'varlix' do
    stub_request(:get, ExchangeRates::Varlix::URL)
      .to_return(body: '<div><span>Dólar Americano</span> <span>38,90</span> <span>41,40</span></div>')

    assert_equal [['Varlix', 'counter', 38.9, 41.4]], rates('varlix')
  end

  test 'cambilex: pizarra y finza' do
    stub_request(:get, ExchangeRates::Cambilex::URL).to_return(body: CAMBILEX_HTML)

    assert_equal [['Cambilex', 'counter', 39.4, 41.8], ['Cambilex Finza', 'online', 40.05, 40.95]], rates('cambilex')
  end

  test 'indumex: API del dia con la fecha de Montevideo' do
    travel_to Time.utc(2026, 11, 19, 1, 0) do # 18/11 22:00 en Montevideo
      body = [{ Compra: 0.02, Venta: 0.035, Moneda: '2' }, { Compra: 39.4, Venta: 41.8, Moneda: '1' }].to_json
      stub_request(:get, "#{ExchangeRates::Indumex::API_URL}18112026").to_return(body:)

      assert_equal [['Indumex', 'counter', 39.4, 41.8]], rates('indumex')
    end
  end

  test 'gales: ultimo dia con cotizacion, salteando el dia siguiente en 0' do
    stub_request(:get, ExchangeRates::Gales::PAGE)
      .to_return(body: '<form name="monedas-form"><input type="hidden" name="_wpnonce" value="abc123"></form>')
    days = [
      { fecha: '2026-11-17', compra: '39.35', venta: '41.75' },
      { fecha: '2026-11-18', compra: '39.45', venta: '41.85' },
      { fecha: '2026-11-19', compra: '0', venta: '0' }
    ]
    stub_request(:post, ExchangeRates::Gales::AJAX_URL)
      .with(body: hash_including('_wpnonce' => 'abc123', 'moneda' => '2222'))
      .to_return(body: { success: true, data: days }.to_json)

    assert_equal [['Gales', 'counter', 39.45, 41.85]], rates('gales')
  end

  test 'matriz: fila con guion entre compra y venta' do
    stub_request(:get, ExchangeRates::Matriz::URL)
      .to_return(body: '<table><tr><td class="nom"> dolar </td><td>39.40</td><td>-</td><td>41.80</td></tr></table>')

    assert_equal [['Cambio Matriz', 'counter', 39.4, 41.8]], rates('matriz')
  end

  test 'cambio18: tabla de Wix con celdas pegadas' do
    stub_request(:get, ExchangeRates::Cambio18::URL).to_return(body: CAMBIO18_HTML)

    assert_equal [['Cambio 18', 'counter', 39.4, 41.8]], rates('cambio18')
  end

  test 'aeromar: primer valor de las columnas compra y venta' do
    stub_request(:get, ExchangeRates::Aeromar::URL).to_return(body: AEROMAR_HTML)

    assert_equal [['Aeromar', 'counter', 39.4, 41.8]], rates('aeromar')
  end

  test 'bcu: referencia' do
    stub_request(:get, ExchangeRates::Bcu::URL)
      .to_return(body: "<div id='identificador-moneda-2225'><span class='bcu-number'>40,643</span></div>")

    assert_equal [['BCU (referencia)', 'reference', 40.643, 40.643]], rates('bcu')
  end
end
