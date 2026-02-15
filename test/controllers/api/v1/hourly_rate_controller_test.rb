require "test_helper"

class Api::V1::HourlyRateControllerTest < ActionDispatch::IntegrationTest
  test "returns hourly rate calculation" do
    get api_v1_salary_hourly_rate_path, params: { salary: 50_000, sector: 'commerce' }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "commerce", json["sector"]
    assert_equal 190, json["monthly_divisor"]
    assert json["base_hourly_rate"] > 0
    assert json["overtime_rate"] > json["base_hourly_rate"]
    assert_equal "UYU", json["currency"]
  end

  test "returns error when salary is missing" do
    get api_v1_salary_hourly_rate_path, params: { sector: 'commerce' }

    assert_response :unprocessable_entity
  end

  test "returns error when salary is negative" do
    get api_v1_salary_hourly_rate_path, params: { salary: -1000, sector: 'commerce' }

    assert_response :unprocessable_entity
  end

  test "returns error when sector is missing" do
    get api_v1_salary_hourly_rate_path, params: { salary: 50_000 }

    assert_response :unprocessable_entity
  end

  test "returns error for invalid sector" do
    get api_v1_salary_hourly_rate_path, params: { salary: 50_000, sector: 'invalid' }

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_match(/Sector inválido/, json["error"])
  end

  test "accepts all valid sectors" do
    %w[commerce industry standard domestic rural].each do |sector|
      get api_v1_salary_hourly_rate_path, params: { salary: 50_000, sector: }

      assert_response :success, "Failed for sector: #{sector}"
    end
  end
end
