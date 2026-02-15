require "test_helper"

class Api::V1::UnemploymentControllerTest < ActionDispatch::IntegrationTest
  test "returns unemployment calculation for dismissal" do
    get api_v1_salary_unemployment_path, params: { salary: 50_000, reason: 'dismissal' }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "dismissal", json["reason"]
    assert_equal 6, json["duration_months"]
    assert json["total_benefit"] > 0
    assert_equal "UYU", json["currency"]
  end

  test "returns unemployment calculation for suspension" do
    get api_v1_salary_unemployment_path, params: { salary: 50_000, reason: 'suspension' }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "suspension", json["reason"]
    assert_equal 4, json["duration_months"]
  end

  test "returns error when salary is missing" do
    get api_v1_salary_unemployment_path, params: { reason: 'dismissal' }

    assert_response :unprocessable_entity
  end

  test "returns error when reason is missing" do
    get api_v1_salary_unemployment_path, params: { salary: 50_000 }

    assert_response :unprocessable_entity
  end

  test "returns error for invalid reason" do
    get api_v1_salary_unemployment_path, params: { salary: 50_000, reason: 'invalid' }

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_match(/Razón inválida/, json["error"])
  end

  test "accepts has_dependents parameter" do
    get api_v1_salary_unemployment_path, params: { salary: 50_000, reason: 'dismissal', has_dependents: true }

    assert_response :success

    json = JSON.parse(response.body)
    assert json["has_dependents"]
  end

  test "accepts age parameter for extension" do
    get api_v1_salary_unemployment_path, params: { salary: 50_000, reason: 'dismissal', age: 55 }

    assert_response :success

    json = JSON.parse(response.body)
    assert json["age_50_plus"]
    assert_equal 12, json["duration_months"]
  end

  test "accepts daily worker type" do
    get api_v1_salary_unemployment_path, params: { salary: 50_000, reason: 'dismissal', worker_type: 'daily', daily_rate: 2_000 }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "daily", json["worker_type"]
  end

  test "monthly_benefits has correct structure" do
    get api_v1_salary_unemployment_path, params: { salary: 50_000, reason: 'dismissal' }

    json = JSON.parse(response.body)
    benefit = json["monthly_benefits"].first

    assert_includes benefit, "month"
    assert_includes benefit, "amount"
  end
end
