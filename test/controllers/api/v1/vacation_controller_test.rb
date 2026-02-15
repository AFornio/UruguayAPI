require "test_helper"

class Api::V1::VacationControllerTest < ActionDispatch::IntegrationTest
  test "returns vacation calculation" do
    get api_v1_salary_vacation_path, params: { salary: 50_000, years_worked: 3 }

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 20, json["vacation_days"]
    assert json["gross_vacation_pay"] > 0
    assert json["net_vacation_pay"] > 0
    assert_equal "UYU", json["currency"]
  end

  test "returns error when salary is missing" do
    get api_v1_salary_vacation_path, params: { years_worked: 3 }

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "El parámetro 'salary' es requerido", json["error"]
  end

  test "returns error when salary is negative" do
    get api_v1_salary_vacation_path, params: { salary: -1000, years_worked: 3 }

    assert_response :unprocessable_entity
  end

  test "returns error when years_worked is missing" do
    get api_v1_salary_vacation_path, params: { salary: 50_000 }

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_equal "El parámetro 'years_worked' es requerido", json["error"]
  end

  test "accepts domestic worker parameter" do
    get api_v1_salary_vacation_path, params: { salary: 50_000, years_worked: 3, is_domestic: true }

    assert_response :success

    json = JSON.parse(response.body)
    assert json["is_domestic"]
  end

  test "accepts spouse and children parameters" do
    get api_v1_salary_vacation_path, params: { salary: 50_000, years_worked: 3, has_spouse: true, children: 2 }

    assert_response :success
  end

  test "more years gives more vacation days" do
    get api_v1_salary_vacation_path, params: { salary: 50_000, years_worked: 2 }
    short = JSON.parse(response.body)

    get api_v1_salary_vacation_path, params: { salary: 50_000, years_worked: 10 }
    long = JSON.parse(response.body)

    assert long["vacation_days"] > short["vacation_days"]
  end
end
