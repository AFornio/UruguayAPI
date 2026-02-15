require "test_helper"

class SalaryServiceTest < ActiveSupport::TestCase
  test "returns correct structure" do
    result = SalaryService.new(salary: 50_000).calculate

    assert_includes result, :gross_salary
    assert_includes result, :deductions
    assert_includes result, :net_salary
    assert_includes result, :bpc
    assert_includes result, :currency
    assert_equal "UYU", result[:currency]
    assert_equal SalaryService::BPC, result[:bpc]

    deductions = result[:deductions]
    assert_includes deductions, :bps
    assert_includes deductions, :fonasa
    assert_includes deductions, :frl
    assert_includes deductions, :irpf
    assert_includes deductions, :total
  end

  test "net salary equals gross minus total deductions" do
    result = SalaryService.new(salary: 50_000).calculate

    expected_net = result[:gross_salary] - result[:deductions][:total]
    assert_in_delta expected_net, result[:net_salary], 0.01
  end

  test "BPS is 15 percent of salary" do
    result = SalaryService.new(salary: 50_000).calculate

    assert_in_delta 7_500.0, result[:deductions][:bps], 0.01
  end

  test "BPS is capped at max salary" do
    result = SalaryService.new(salary: 300_000).calculate

    expected_bps = SalaryService::BPS_CAP * SalaryService::BPS_RATE
    assert_in_delta expected_bps, result[:deductions][:bps], 0.01
  end

  test "FRL is 0.1 percent of salary" do
    result = SalaryService.new(salary: 50_000).calculate

    assert_in_delta 50.0, result[:deductions][:frl], 0.01
  end

  test "FONASA low bracket without spouse or children" do
    salary = SalaryService::BPC * 2 # Below 2.5 BPC threshold
    result = SalaryService.new(salary:).calculate

    expected_fonasa = salary * 0.03
    assert_in_delta expected_fonasa, result[:deductions][:fonasa], 0.01
  end

  test "FONASA high bracket without spouse or children" do
    salary = 50_000 # Above 2.5 BPC threshold
    result = SalaryService.new(salary:).calculate

    expected_fonasa = salary * 0.045
    assert_in_delta expected_fonasa, result[:deductions][:fonasa], 0.01
  end

  test "FONASA with spouse adds 2 percent" do
    salary = 50_000
    result = SalaryService.new(salary:, has_spouse: true).calculate

    expected_fonasa = salary * (0.045 + 0.02)
    assert_in_delta expected_fonasa, result[:deductions][:fonasa], 0.01
  end

  test "FONASA with children adds 1.5 percent in high bracket" do
    salary = 50_000
    result = SalaryService.new(salary:, children: 1).calculate

    expected_fonasa = salary * (0.045 + 0.015)
    assert_in_delta expected_fonasa, result[:deductions][:fonasa], 0.01
  end

  test "FONASA with spouse and children" do
    salary = 50_000
    result = SalaryService.new(salary:, has_spouse: true, children: 2).calculate

    expected_fonasa = salary * (0.045 + 0.02 + 0.015)
    assert_in_delta expected_fonasa, result[:deductions][:fonasa], 0.01
  end

  test "IRPF is zero for salary below 7 BPC" do
    salary = SalaryService::BPC * 5
    result = SalaryService.new(salary:).calculate

    assert_equal 0.0, result[:deductions][:irpf]
  end

  test "IRPF is positive for salary above 7 BPC" do
    salary = SalaryService::BPC * 20
    result = SalaryService.new(salary:).calculate

    assert result[:deductions][:irpf] > 0
  end

  test "higher salary yields higher IRPF" do
    low = SalaryService.new(salary: 80_000).calculate
    high = SalaryService.new(salary: 150_000).calculate

    assert high[:deductions][:irpf] > low[:deductions][:irpf]
  end

  test "children reduce IRPF" do
    without_children = SalaryService.new(salary: 100_000).calculate
    with_children = SalaryService.new(salary: 100_000, children: 2).calculate

    assert with_children[:deductions][:irpf] < without_children[:deductions][:irpf]
  end

  test "disabled children deduction is higher than regular children" do
    with_children = SalaryService.new(salary: 100_000, children: 1).calculate
    with_disabled = SalaryService.new(salary: 100_000, disabled_children: 1).calculate

    assert with_disabled[:deductions][:irpf] < with_children[:deductions][:irpf]
  end

  test "gross salary matches input" do
    result = SalaryService.new(salary: 75_000).calculate

    assert_equal 75_000.0, result[:gross_salary]
  end

  test "all deductions sum to total" do
    result = SalaryService.new(salary: 80_000, has_spouse: true, children: 1).calculate
    deductions = result[:deductions]

    expected_total = deductions[:bps] + deductions[:fonasa] + deductions[:frl] + deductions[:irpf]
    assert_in_delta expected_total, deductions[:total], 0.01
  end
end
