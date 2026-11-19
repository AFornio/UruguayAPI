require 'test_helper'
require 'webmock/minitest'

class BeachesServiceTest < ActiveSupport::TestCase
  NOW = Time.utc(2026, 11, 19, 15).freeze
  LATER = '2026-11-19T23:00:00.000Z'.freeze
  EARLIER = '2026-11-19T10:00:00.000Z'.freeze

  def station(beach, flag, expiration: LATER, health: 'false', **extra)
    { properties: { beach:, safetyFlag: flag, safetyFlagExpiration: expiration, healthFlag: health,
                    healthFlagExpiration: LATER, **extra } }
  end

  def stub(stations)
    beaches = [{ id: 'pocitos', name: 'Pocitos', link: 'https://montevideo.gub.uy/node/1', location: [-56.1, -34.9] },
               { id: 'carrasco', name: 'Carrasco', link: 'https://montevideo.gub.uy/node/2', location: [-56.0, -34.8] }]
    weather = { ValorIndiceUV: { value: 8.48 }, TemepraturaActual: { value: 21.8 },
                TemperaturaMaxMin: { tempMax: 24, tempMin: 14 } }
    stub_request(:get, "#{BeachesService::BASE_URL}/playas").to_return(body: beaches.to_json)
    stub_request(:get, "#{BeachesService::BASE_URL}/casillas").to_return(body: { features: stations }.to_json)
    stub_request(:get, "#{BeachesService::BASE_URL}/clima").to_return(body: weather.to_json)
  end

  test 'una fila por playa en el orden de la Intendencia, con UV y temperatura' do
    stub([station('pocitos', 'green')])
    result = BeachesService.fetch_all(now: NOW)

    assert_equal %w[Pocitos Carrasco], result[:beaches].pluck(:name)
    assert_equal [8.48, 21.8, 24, 14], result.values_at(:uv, :temperature, :max_temperature, :min_temperature)
    assert_equal [1, 0], result[:beaches].pluck(:stations)
  end

  test 'la bandera de la playa es la mas restrictiva de sus casillas' do
    stub([station('pocitos', 'green'), station('pocitos', 'red'), station('pocitos', 'yellow')])

    assert_equal 'red', BeachesService.fetch_all(now: NOW)[:beaches].first[:safety_flag]
  end

  test 'una bandera vencida o desconocida no cuenta' do
    stub([station('pocitos', 'red', expiration: EARLIER), station('pocitos', 'purple'), station('carrasco', 'green')])
    pocitos, carrasco = BeachesService.fetch_all(now: NOW)[:beaches]

    assert_nil pocitos[:safety_flag]
    assert_equal 'green', carrasco[:safety_flag]
  end

  test 'alerta sanitaria vigente con su causa' do
    stub([station('pocitos', 'green', health: 'true', healthFlagCauseDesc: 'Lluvias',
                                      healthFlagCauseLongDesc: 'No bañarse 24 hs después de lluvias.')])
    pocitos, carrasco = BeachesService.fetch_all(now: NOW)[:beaches]

    assert_equal({ cause: 'Lluvias', detail: 'No bañarse 24 hs después de lluvias.', until: LATER },
                 pocitos[:health_warning])
    assert_nil carrasco[:health_warning]
  end
end
