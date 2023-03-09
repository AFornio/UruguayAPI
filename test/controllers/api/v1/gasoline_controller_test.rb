require 'test_helper'

class Api::V1::GasolineControllerTest < ActionDispatch::IntegrationTest
  ANCAP_GASOLINE = [
    {name: 'Super 95', url: "https://www.ancap.com.uy/1636/1/super-95.html"},
    {name: 'Premium 97', url: "https://www.ancap.com.uy/1637/1/premium-97.html"},
    {name: 'Gasoil 10-S', url: "https://www.ancap.com.uy/1641/1/gasoil-10-s.html"},
    {name: 'Gasoil 50-S', url: "https://www.ancap.com.uy/1642/1/gasoil--50-s.html"},
  ].freeze

  test "should get index" do
    get api_v1_gasoline_index_path
    assert_response :success
    assert_equal ANCAP_GASOLINE.length, JSON.parse(response.body).length
  end

  test "should get show" do
    gas = ANCAP_GASOLINE.first
    get api_v1_gasoline_path(gas[:name])
    assert_response :success

    response_keys = JSON.parse(response.body).keys
    assert_includes response_keys, "max_price"
    assert_includes response_keys, "ancap_price"
    assert_includes response_keys, "currency"
  end

  test "should get 404 for invalid gasoline name" do
    get api_v1_gasoline_path("Invalid Gas Name")
    assert_response :not_found
    assert_equal "Gasoline type not found", JSON.parse(response.body)["error"]
  end
end
