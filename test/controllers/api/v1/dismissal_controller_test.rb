require "test_helper"

class Api::V1::DismissalControllerTest < ActionDispatch::IntegrationTest
  test "returns dismissal calculation for monthly worker" do
    get api_v1_salary_dismissal_path, params: { salary: 50_000, years_worked: 3 }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 150_000.0, json["base_ipd"]
    assert_equal 3, json["months_compensation"]
    assert_equal "monthly", json["worker_type"]
    assert_equal "UYU", json["currency"]
  end

  test "returns error when salary is missing" do
    get api_v1_salary_dismissal_path, params: { years_worked: 3 }

    assert_response :unprocessable_entity
  end

  test "returns error when salary is negative" do
    get api_v1_salary_dismissal_path, params: { salary: -1000, years_worked: 3 }

    assert_response :unprocessable_entity
  end

  test "returns error when years_worked is missing" do
    get api_v1_salary_dismissal_path, params: { salary: 50_000 }

    assert_response :unprocessable_entity
  end

  test "accepts daily worker type" do
    get api_v1_salary_dismissal_path, params: { salary: 2_000, years_worked: 1, worker_type: 'daily', days_worked: 150 }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "daily", json["worker_type"]
  end

  test "accepts domestic worker type" do
    get api_v1_salary_dismissal_path, params: { salary: 30_000, years_worked: 2, worker_type: 'domestic' }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "domestic", json["worker_type"]
  end

  test "accepts aggravating factor" do
    get api_v1_salary_dismissal_path, params: { salary: 50_000, years_worked: 3, aggravating_factor: 'illness' }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "illness", json["aggravating_factor"]
    assert json["aggravating_amount"] > 0
    assert json["total_ipd"] > json["base_ipd"]
  end

  test "accepts months_fraction parameter" do
    get api_v1_salary_dismissal_path, params: { salary: 50_000, years_worked: 2, months_fraction: 3 }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 3, json["months_compensation"]
  end
end
