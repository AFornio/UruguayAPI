require 'test_helper'
require 'minitest/mock'

class Api::V1::BeachesControllerTest < ActionDispatch::IntegrationTest
  test 'devuelve el estado de las playas' do
    BeachesService.stub(:fetch_all, { beaches: [{ name: 'Pocitos', safety_flag: 'green' }], uv: 8 }) do
      get api_v1_beaches_root_path
    end

    assert_response :success
    assert_equal 'green', response.parsed_body['beaches'].first['safety_flag']
  end

  test 'si la Intendencia no responde devuelve 500 con el motivo' do
    BeachesService.stub(:fetch_all, -> { raise Scraper::BlockedError, 'pci respondió 503' }) do
      get api_v1_beaches_root_path
    end

    assert_response :internal_server_error
    assert_match '503', response.parsed_body['error']
  end
end
