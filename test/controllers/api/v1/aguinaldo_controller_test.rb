require "test_helper"

class Api::V1::AguinaldoControllerTest < ActionDispatch::IntegrationTest
  test "returns aguinaldo with fixed salary" do
    get api_v1_salary_aguinaldo_path, params: { monthly_salaries: 50_000 }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 25_000.0, json["gross_aguinaldo"]
    assert json["net_aguinaldo"] > 0
    assert json["deductions"]["total"] > 0
    assert_equal "UYU", json["currency"]
  end

  test "returns aguinaldo with variable salaries" do
    get api_v1_salary_aguinaldo_path, params: { monthly_salaries: "40000,42000,45000,48000,50000,55000" }

    assert_response :success

    json = JSON.parse(response.body)
    assert_in_delta 23_333.33, json["gross_aguinaldo"], 0.01
  end

  test "returns aguinaldo with array params" do
    get api_v1_salary_aguinaldo_path, params: { monthly_salaries: [40_000, 50_000, 60_000] }

    assert_response :success

    json = JSON.parse(response.body)
    assert_in_delta 12_500.0, json["gross_aguinaldo"], 0.01
  end

  test "returns error when monthly_salaries is missing" do
    get api_v1_salary_aguinaldo_path

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "El parámetro 'monthly_salaries' es requerido", json["error"]
  end

  test "returns error when salary is negative" do
    get api_v1_salary_aguinaldo_path, params: { monthly_salaries: "-1000" }

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "Los salarios deben ser números positivos", json["error"]
  end

  test "returns error when more than 6 salaries" do
    get api_v1_salary_aguinaldo_path, params: { monthly_salaries: "1,2,3,4,5,6,7" }

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "Se requieren entre 1 y 6 salarios mensuales", json["error"]
  end

  test "accepts spouse parameter" do
    get api_v1_salary_aguinaldo_path, params: { monthly_salaries: 50_000, has_spouse: true }

    assert_response :success

    json = JSON.parse(response.body)
    assert json["deductions"]["fonasa"] > 0
  end

  test "accepts children parameter" do
    get api_v1_salary_aguinaldo_path, params: { monthly_salaries: 100_000, children: 2 }

    assert_response :success
  end

  test "response includes monthly_salaries array" do
    get api_v1_salary_aguinaldo_path, params: { monthly_salaries: 50_000 }

    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json["monthly_salaries"]
  end

  test "deductions contain expected fields" do
    get api_v1_salary_aguinaldo_path, params: { monthly_salaries: 50_000 }

    json = JSON.parse(response.body)
    deductions = json["deductions"]

    assert_includes deductions, "bps"
    assert_includes deductions, "fonasa"
    assert_includes deductions, "frl"
    assert_includes deductions, "irpf"
    assert_includes deductions, "total"
  end
end
