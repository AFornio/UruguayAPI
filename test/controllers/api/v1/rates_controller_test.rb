require 'test_helper'

class Api::V1::RatesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_rates_index_url
    assert_response :success
    
    rates = JSON.parse(@response.body)
    assert_not_nil rates["dolar"]
    assert_not_nil rates["dolar_ebrou"]
    assert_not_nil rates["euro"]
    assert_not_nil rates["peso_argentino"]
    assert_not_nil rates["real"]
    assert_not_nil rates["libra_esterlina"]
    assert_not_nil rates["franco_suizo"]
    assert_not_nil rates["guarani"]
    assert_not_nil rates["unidad_indexada"]
    assert_not_nil rates["onza_troy_de_oro"]
  end
end
