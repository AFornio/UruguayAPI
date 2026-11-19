require 'test_helper'
require 'webmock/minitest'

class StreetMarketsServiceTest < ActiveSupport::TestCase
  def segment(code, day, name, location, type: 'Feria alimentaria', hours: %w[07:00 14:00], ring: nil)
    {
      type: 'Feature',
      geometry: { type: 'Polygon', coordinates: [ring || [[-56.168, -34.904], [-56.167, -34.906]]] },
      properties: { COD_FERIA: code, DIA: day, NOMBRE: name, BARRIO: 'CORDON', UBICACION: location, TIPO: type,
                    HORA_INICIO: hours.first, HORA_FIN: hours.last }
    }
  end

  def stub(features)
    stub_request(:get, StreetMarketsService::URL).to_return(body: { features: }.to_json)
  end

  test 'los tramos con el mismo codigo y dia son una sola feria, con el tramo principal primero' do
    stub([
           segment('A30203', 'Martes', 'Juan Paullier ',
                   'continuación de la feria sobre la calle Juan Paullier desde Guaná hasta Charrúa.',
                   type: 'Periferia', hours: %w[07:00 15:00], ring: [[-56.168, -34.903], [-56.168, -34.905]]),
           segment('A30203', 'Martes', 'Juan Paullier', 'Juan Paullier desde Chaná hasta Guaná',
                   ring: [[-56.166, -34.905], [-56.166, -34.907]])
         ])
    market = StreetMarketsService.fetch_all.sole

    assert_equal ['A30203-2', 'Juan Paullier', 'Cordon', 2], market.values_at(:id, :name, :neighborhood, :weekday)
    assert_equal %w[07:00 15:00], market.values_at(:opens, :closes)
    assert market[:food]
    assert_equal 'Juan Paullier desde Chaná hasta Guaná', market[:segments].first
    assert_in_delta(-34.905, market[:latitude], 0.0001)
    assert_in_delta(-56.167, market[:longitude], 0.0001)
    assert_equal [[[-34.903, -56.168], [-34.905, -56.168]], [[-34.905, -56.166], [-34.907, -56.166]]],
                 market[:shapes]
  end

  test 'el mismo codigo en otro dia es otra feria; ordenadas por dia de la semana' do
    stub([segment('B1', 'Domingo', 'Tristán Narvaja', 'Tristán Narvaja y 18 de Julio'),
          segment('C1', 'Miércoles', 'San Salvador', 'San Salvador'),
          segment('C1', 'Sábado', 'San Salvador', 'San Salvador')])

    assert_equal([[3, 'San Salvador'], [6, 'San Salvador'], [7, 'Tristán Narvaja']],
                 StreetMarketsService.fetch_all.map { |m| m.values_at(:weekday, :name) })
  end

  test 'una feria solo de periferia o no alimentaria no cuenta como de comida; dia desconocido se descarta' do
    stub([segment('D1', 'Jueves', 'Artesanos', 'Plaza', type: 'Feria no alimentaria'),
          segment('E1', 'Feriado', 'Rara', 'X')])

    assert_equal [false], StreetMarketsService.fetch_all.pluck(:food)
  end
end
