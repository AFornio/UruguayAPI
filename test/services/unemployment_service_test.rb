require "test_helper"

class UnemploymentServiceTest < ActiveSupport::TestCase
  # --- Dismissal monthly ---

  test "dismissal monthly has 6 months of benefits" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal').calculate

    assert_equal 6, result[:duration_months]
  end

  test "dismissal month 1 is 66% of salary" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal').calculate

    assert_in_delta 33_000.0, result[:monthly_benefits][0][:amount], 0.01
  end

  test "dismissal month 2 is 57% of salary" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal').calculate

    assert_in_delta 28_500.0, result[:monthly_benefits][1][:amount], 0.01
  end

  test "dismissal month 6 is 40% of salary" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal').calculate

    assert_in_delta 20_000.0, result[:monthly_benefits][5][:amount], 0.01
  end

  test "dismissal benefits are decreasing" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal').calculate
    amounts = result[:monthly_benefits].map { |b| b[:amount] }

    amounts.each_cons(2) { |a, b| assert a >= b }
  end

  test "total benefit is sum of all months" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal').calculate
    expected = result[:monthly_benefits].sum { |b| b[:amount] }

    assert_in_delta expected, result[:total_benefit], 0.01
  end

  # --- Suspension ---

  test "suspension has 4 months at 50%" do
    result = UnemploymentService.new(salary: 50_000, reason: 'suspension').calculate

    assert_equal 4, result[:duration_months]
    result[:monthly_benefits].each do |b|
      assert_in_delta 25_000.0, b[:amount], 0.01
    end
  end

  # --- Dependents ---

  test "dependents add 20% to benefits" do
    without = UnemploymentService.new(salary: 50_000, reason: 'dismissal').calculate
    with_deps = UnemploymentService.new(salary: 50_000, reason: 'dismissal', has_dependents: true).calculate

    assert_in_delta without[:monthly_benefits][0][:amount] * 1.2, with_deps[:monthly_benefits][0][:amount], 0.01
  end

  test "dependents apply to suspension too" do
    with_deps = UnemploymentService.new(salary: 50_000, reason: 'suspension', has_dependents: true).calculate

    assert_in_delta 30_000.0, with_deps[:monthly_benefits][0][:amount], 0.01
  end

  # --- Age 50+ extension ---

  test "age 50+ extends dismissal by 6 months at 40%" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal', age: 55).calculate

    assert_equal 12, result[:duration_months]
    assert_in_delta 20_000.0, result[:monthly_benefits][6][:amount], 0.01
  end

  test "age under 50 does not extend" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal', age: 45).calculate

    assert_equal 6, result[:duration_months]
  end

  # --- Daily worker ---

  test "daily dismissal uses jornales schedule" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal', worker_type: 'daily', daily_rate: 2_000).calculate

    # Month 1: 16 jornales × 2,000 = 32,000
    assert_in_delta 32_000.0, result[:monthly_benefits][0][:amount], 0.01
    # Month 6: 9 jornales × 2,000 = 18,000
    assert_in_delta 18_000.0, result[:monthly_benefits][5][:amount], 0.01
  end

  test "daily dismissal with age 50+ extends" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal', worker_type: 'daily', daily_rate: 2_000, age: 52).calculate

    assert_equal 12, result[:duration_months]
    # Extension months: 9 jornales × 2,000 = 18,000
    assert_in_delta 18_000.0, result[:monthly_benefits][6][:amount], 0.01
  end

  # --- General ---

  test "returns currency" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal').calculate

    assert_equal "UYU", result[:currency]
  end

  test "returns reason" do
    result = UnemploymentService.new(salary: 50_000, reason: 'suspension').calculate

    assert_equal "suspension", result[:reason]
  end

  test "returns worker_type" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal', worker_type: 'daily', daily_rate: 2_000).calculate

    assert_equal "daily", result[:worker_type]
  end

  test "returns has_dependents flag" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal', has_dependents: true).calculate

    assert result[:has_dependents]
  end

  test "returns age_50_plus flag" do
    result = UnemploymentService.new(salary: 50_000, reason: 'dismissal', age: 55).calculate

    assert result[:age_50_plus]
  end

  test "invalid reason returns empty benefits" do
    result = UnemploymentService.new(salary: 50_000, reason: 'invalid').calculate

    assert_equal 0, result[:duration_months]
    assert_equal 0.0, result[:total_benefit]
  end
end
