require "test_helper"

class Api::V1::SalaryControllerTest < ActionDispatch::IntegrationTest
  test "returns net salary calculation" do
    get api_v1_salary_net_path, params: { salary: 50_000 }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 50_000.0, json["gross_salary"]
    assert json["net_salary"] > 0
    assert json["deductions"]["total"] > 0
    assert_equal "UYU", json["currency"]
  end

  test "returns error when salary is missing" do
    get api_v1_salary_net_path

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "El parámetro 'salary' es requerido", json["error"]
  end

  test "returns error when salary is negative" do
    get api_v1_salary_net_path, params: { salary: -1000 }

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "El salario debe ser un número positivo", json["error"]
  end

  test "returns error when salary is zero" do
    get api_v1_salary_net_path, params: { salary: 0 }

    assert_response :unprocessable_entity
  end

  test "accepts optional spouse parameter" do
    get api_v1_salary_net_path, params: { salary: 50_000, has_spouse: true }

    assert_response :success

    json = JSON.parse(response.body)
    assert json["deductions"]["fonasa"] > 0
  end

  test "accepts optional children parameter" do
    get api_v1_salary_net_path, params: { salary: 100_000, children: 2 }

    assert_response :success
  end

  test "accepts optional disabled_children parameter" do
    get api_v1_salary_net_path, params: { salary: 100_000, disabled_children: 1 }

    assert_response :success
  end

  test "spouse increases fonasa deduction" do
    get api_v1_salary_net_path, params: { salary: 50_000 }
    without_spouse = JSON.parse(response.body)

    get api_v1_salary_net_path, params: { salary: 50_000, has_spouse: true }
    with_spouse = JSON.parse(response.body)

    assert with_spouse["deductions"]["fonasa"] > without_spouse["deductions"]["fonasa"]
  end
end
