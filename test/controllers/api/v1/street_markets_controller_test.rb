require 'test_helper'
require 'minitest/mock'

class Api::V1::StreetMarketsControllerTest < ActionDispatch::IntegrationTest
  test 'devuelve las ferias' do
    StreetMarketsService.stub(:fetch_all, [{ name: 'Juan Paullier', weekday: 2 }]) do
      get api_v1_street_markets_root_path
    end

    assert_response :success
    assert_equal 'Juan Paullier', response.parsed_body.first['name']
  end

  test 'si el geoserver no responde devuelve 500 con el motivo' do
    StreetMarketsService.stub(:fetch_all, -> { raise Scraper::BlockedError, 'geoserver respondió 503' }) do
      get api_v1_street_markets_root_path
    end

    assert_response :internal_server_error
    assert_match '503', response.parsed_body['error']
  end
end
