require 'test_helper'
require 'minitest/mock'

class Api::V1::ExchangeRatesControllerTest < ActionDispatch::IntegrationTest
  test 'devuelve cotizaciones y errores' do
    result = { rates: [{ source: 'varlix', kind: 'counter', buy: 38.9, sell: 41.4 }], errors: { 'gales' => '403' } }

    ExchangeRates.stub(:fetch_all, result) { get api_v1_exchange_rates_root_path }

    assert_response :success
    assert_equal 'varlix', response.parsed_body['rates'].first['source']
    assert_equal({ 'gales' => '403' }, response.parsed_body['errors'])
  end
end
