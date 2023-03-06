require 'test_helper'

class Api::V1::BusesControllerTest < ActionController::TestCase
  test "should get options" do
    get :options
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["origins_and_destinations"]
    assert_not_nil json_response["companies"]
    assert_not_nil json_response["days"]
    assert_not_nil json_response["shifts"]
  end

  test "should get schedules" do
    get :schedules, params: { origin: "Montevideo", destination: "Punta del Este" }
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["schedules"]
    assert_not_nil json_response["pagination"]
  end

  test "should return error when origin and destination are not present" do
    get :schedules
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["error"]
  end

  test "should return error when origin and destination are not present for all_schedules" do
    get :all_schedules
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_not_nil json_response["error"]
  end
end
