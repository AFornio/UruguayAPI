require "test_helper"

class VacationServiceTest < ActiveSupport::TestCase
  test "base vacation is 20 days for less than 5 years" do
    result = VacationService.new(salary: 50_000, years_worked: 3).calculate

    assert_equal 20, result[:vacation_days]
  end

  test "21 days at 5 years" do
    result = VacationService.new(salary: 50_000, years_worked: 5).calculate

    assert_equal 21, result[:vacation_days]
  end

  test "22 days at 9 years" do
    result = VacationService.new(salary: 50_000, years_worked: 9).calculate

    assert_equal 22, result[:vacation_days]
  end

  test "23 days at 13 years" do
    result = VacationService.new(salary: 50_000, years_worked: 13).calculate

    assert_equal 23, result[:vacation_days]
  end

  test "24 days at 17 years" do
    result = VacationService.new(salary: 50_000, years_worked: 17).calculate

    assert_equal 24, result[:vacation_days]
  end

  test "25 days at 21 years" do
    result = VacationService.new(salary: 50_000, years_worked: 21).calculate

    assert_equal 25, result[:vacation_days]
  end

  test "20 days for 0 years" do
    result = VacationService.new(salary: 50_000, years_worked: 0).calculate

    assert_equal 20, result[:vacation_days]
  end

  test "calculates gross vacation pay from net salary" do
    # Net salary for 50,000: use SalaryService to get exact value
    net = SalaryService.new(salary: 50_000).calculate[:net_salary]
    expected_gross = (net / 30.0) * 20

    result = VacationService.new(salary: 50_000, years_worked: 3).calculate

    assert_in_delta expected_gross, result[:gross_vacation_pay], 0.01
  end

  test "domestic worker gets 15% premium" do
    regular = VacationService.new(salary: 50_000, years_worked: 3).calculate
    domestic = VacationService.new(salary: 50_000, years_worked: 3, is_domestic: true).calculate

    assert_in_delta regular[:gross_vacation_pay] * 1.15, domestic[:gross_vacation_pay], 0.01
  end

  test "low salary has zero IRPF on vacation pay" do
    result = VacationService.new(salary: 30_000, years_worked: 3).calculate

    # 30,000 is below 7 BPC (43,239) → marginal rate = 0%
    assert_equal 0.0, result[:irpf]
  end

  test "high salary has IRPF on vacation pay" do
    result = VacationService.new(salary: 100_000, years_worked: 3).calculate

    assert result[:irpf] > 0
  end

  test "net vacation pay is gross minus IRPF" do
    result = VacationService.new(salary: 50_000, years_worked: 3).calculate

    expected_net = result[:gross_vacation_pay] - result[:irpf]
    assert_in_delta expected_net, result[:net_vacation_pay], 0.01
  end

  test "returns currency" do
    result = VacationService.new(salary: 50_000, years_worked: 3).calculate

    assert_equal "UYU", result[:currency]
  end

  test "returns is_domestic flag" do
    result = VacationService.new(salary: 50_000, years_worked: 3, is_domestic: true).calculate

    assert result[:is_domestic]
  end

  test "returns years_worked" do
    result = VacationService.new(salary: 50_000, years_worked: 7).calculate

    assert_equal 7, result[:years_worked]
  end
end
