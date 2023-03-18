require "test_helper"

class Api::V1::HolidaysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @year = Time.now.year
  end

  test "should get show" do
    get api_v1_holidays_path(year: @year)
    assert_response :success
    assert JSON.parse(response.body).length > 0
  end

  test "should get official" do
    get "/api/v1/holidays/official/#{@year}"
    assert_response :success
    assert JSON.parse(response.body).length > 0
  end

  test "should get official and non-working" do
    get "/api/v1/holidays/official_and_non_working/#{@year}"
    assert_response :success
    assert JSON.parse(response.body).length > 0
  end

  test "should get holidays and observances" do
    get "/api/v1/holidays/holidays_and_observances/#{@year}"
    assert_response :success
    assert JSON.parse(response.body).length > 0
  end

  test "should get holidays and observances including locals" do
    get "/api/v1/holidays/holidays_and_observances_including_locals/#{@year}"
    assert_response :success
    assert JSON.parse(response.body).length > 0
  end

  test "should return error for invalid year" do
    get "/api/v1/holidays/InvalidYear"
    assert_response :bad_request
    assert JSON.parse(response.body)["error"] == "Invalid year"
  end
end
