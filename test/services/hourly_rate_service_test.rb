require "test_helper"

class HourlyRateServiceTest < ActiveSupport::TestCase
  test "commerce sector uses divisor 190" do
    result = HourlyRateService.new(salary: 50_000, sector: 'commerce').calculate

    assert_equal 190, result[:monthly_divisor]
    assert_equal 44, result[:weekly_hours]
    assert_in_delta 263.16, result[:base_hourly_rate], 0.01
  end

  test "industry sector uses divisor 208" do
    result = HourlyRateService.new(salary: 50_000, sector: 'industry').calculate

    assert_equal 208, result[:monthly_divisor]
    assert_equal 48, result[:weekly_hours]
    assert_in_delta 240.38, result[:base_hourly_rate], 0.01
  end

  test "standard sector uses divisor 173" do
    result = HourlyRateService.new(salary: 50_000, sector: 'standard').calculate

    assert_equal 173, result[:monthly_divisor]
    assert_equal 40, result[:weekly_hours]
    assert_in_delta 289.02, result[:base_hourly_rate], 0.01
  end

  test "domestic sector uses divisor 190" do
    result = HourlyRateService.new(salary: 50_000, sector: 'domestic').calculate

    assert_equal 190, result[:monthly_divisor]
  end

  test "rural sector uses divisor 208" do
    result = HourlyRateService.new(salary: 50_000, sector: 'rural').calculate

    assert_equal 208, result[:monthly_divisor]
  end

  test "overtime is 2x base rate" do
    result = HourlyRateService.new(salary: 50_000, sector: 'commerce').calculate

    assert_in_delta result[:base_hourly_rate] * 2, result[:overtime_rate], 0.01
  end

  test "holiday rate is 2.5x base rate" do
    result = HourlyRateService.new(salary: 50_000, sector: 'commerce').calculate

    assert_in_delta result[:base_hourly_rate] * 2.5, result[:holiday_rate], 0.02
  end

  test "night rate is 1.2x base rate" do
    result = HourlyRateService.new(salary: 50_000, sector: 'commerce').calculate

    assert_in_delta result[:base_hourly_rate] * 1.2, result[:night_rate], 0.01
  end

  test "invalid sector returns nil" do
    result = HourlyRateService.new(salary: 50_000, sector: 'invalid').calculate

    assert_nil result
  end

  test "returns currency" do
    result = HourlyRateService.new(salary: 50_000, sector: 'commerce').calculate

    assert_equal "UYU", result[:currency]
  end

  test "returns sector name" do
    result = HourlyRateService.new(salary: 50_000, sector: 'industry').calculate

    assert_equal "industry", result[:sector]
  end
end
