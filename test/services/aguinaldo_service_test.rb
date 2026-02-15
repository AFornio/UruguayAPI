require "test_helper"

class AguinaldoServiceTest < ActiveSupport::TestCase
  test "calculates gross aguinaldo from fixed salary" do
    result = AguinaldoService.new(monthly_salaries: 50_000).calculate

    # 6 × 50,000 / 12 = 25,000
    assert_equal 25_000.0, result[:gross_aguinaldo]
  end

  test "calculates gross aguinaldo from variable salaries" do
    salaries = [40_000, 42_000, 45_000, 48_000, 50_000, 55_000]
    result = AguinaldoService.new(monthly_salaries: salaries).calculate

    # (40000 + 42000 + 45000 + 48000 + 50000 + 55000) / 12 = 280000 / 12 = 23333.33
    assert_in_delta 23_333.33, result[:gross_aguinaldo], 0.01
  end

  test "applies BPS deduction" do
    result = AguinaldoService.new(monthly_salaries: 50_000).calculate

    # BPS = 15% of 25,000 = 3,750
    assert_in_delta 3_750.0, result[:deductions][:bps], 0.01
  end

  test "applies FRL deduction" do
    result = AguinaldoService.new(monthly_salaries: 50_000).calculate

    # FRL = 0.1% of 25,000 = 25
    assert_in_delta 25.0, result[:deductions][:frl], 0.01
  end

  test "applies FONASA deduction" do
    result = AguinaldoService.new(monthly_salaries: 50_000).calculate

    # 25,000 > 2.5 × 6,177 = 15,442.50 → high rate: 4.5%
    # FONASA = 4.5% of 25,000 = 1,125
    assert_in_delta 1_125.0, result[:deductions][:fonasa], 0.01
  end

  test "spouse increases FONASA deduction" do
    without = AguinaldoService.new(monthly_salaries: 50_000).calculate
    with_spouse = AguinaldoService.new(monthly_salaries: 50_000, has_spouse: true).calculate

    assert with_spouse[:deductions][:fonasa] > without[:deductions][:fonasa]
  end

  test "net aguinaldo is gross minus total deductions" do
    result = AguinaldoService.new(monthly_salaries: 50_000).calculate

    expected_net = result[:gross_aguinaldo] - result[:deductions][:total]
    assert_in_delta expected_net, result[:net_aguinaldo], 0.01
  end

  test "returns monthly_salaries in response" do
    result = AguinaldoService.new(monthly_salaries: 50_000).calculate

    assert_equal [50_000.0] * 6, result[:monthly_salaries]
  end

  test "returns currency" do
    result = AguinaldoService.new(monthly_salaries: 50_000).calculate

    assert_equal "UYU", result[:currency]
  end

  test "handles single salary in array" do
    result = AguinaldoService.new(monthly_salaries: [60_000]).calculate

    # 60,000 / 12 = 5,000
    assert_equal 5_000.0, result[:gross_aguinaldo]
  end

  test "handles partial semester (3 months)" do
    salaries = [30_000, 35_000, 40_000]
    result = AguinaldoService.new(monthly_salaries: salaries).calculate

    # (30000 + 35000 + 40000) / 12 = 105000 / 12 = 8750
    assert_in_delta 8_750.0, result[:gross_aguinaldo], 0.01
  end

  test "children reduce IRPF via deduction credit" do
    without = AguinaldoService.new(monthly_salaries: 200_000).calculate
    with_children = AguinaldoService.new(monthly_salaries: 200_000, children: 2).calculate

    assert with_children[:deductions][:irpf] < without[:deductions][:irpf]
  end

  test "low salary has zero IRPF" do
    result = AguinaldoService.new(monthly_salaries: 20_000).calculate

    # 20,000 × 6 / 12 = 10,000 → below 7 BPC (43,239) → IRPF = 0
    assert_equal 0.0, result[:deductions][:irpf]
  end
end
