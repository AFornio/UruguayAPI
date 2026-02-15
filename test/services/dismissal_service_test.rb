require "test_helper"

class DismissalServiceTest < ActiveSupport::TestCase
  # --- Monthly worker tests ---

  test "monthly worker gets 1 salary per year" do
    result = DismissalService.new(salary: 50_000, years_worked: 3).calculate

    assert_equal 150_000.0, result[:base_ipd]
    assert_equal 3, result[:months_compensation]
  end

  test "monthly worker capped at 6 months" do
    result = DismissalService.new(salary: 50_000, years_worked: 10).calculate

    assert_equal 300_000.0, result[:base_ipd]
    assert_equal 6, result[:months_compensation]
  end

  test "monthly worker fraction counts as full year" do
    result = DismissalService.new(salary: 50_000, years_worked: 2, months_fraction: 3).calculate

    # 2 years + fraction = 3 years
    assert_equal 150_000.0, result[:base_ipd]
    assert_equal 3, result[:months_compensation]
  end

  test "monthly worker with zero years and fraction" do
    result = DismissalService.new(salary: 50_000, years_worked: 0, months_fraction: 5).calculate

    assert_equal 50_000.0, result[:base_ipd]
    assert_equal 1, result[:months_compensation]
  end

  # --- Daily worker tests ---

  test "daily worker below 100 days gets nothing" do
    result = DismissalService.new(salary: 2_000, years_worked: 1, worker_type: 'daily', days_worked: 80).calculate

    assert_equal 0.0, result[:base_ipd]
  end

  test "daily worker 100-239 days gets 2 jornales per 25 days" do
    result = DismissalService.new(salary: 2_000, years_worked: 1, worker_type: 'daily', days_worked: 150).calculate

    # 150 / 25 = 6 groups × 2 = 12 jornales
    assert_equal 24_000.0, result[:base_ipd]
  end

  test "daily worker 240+ days gets 25 jornales per year" do
    result = DismissalService.new(salary: 2_000, years_worked: 3, worker_type: 'daily', days_worked: 300).calculate

    # 25 × 3 = 75 jornales
    assert_equal 150_000.0, result[:base_ipd]
  end

  test "daily worker capped at 150 jornales" do
    result = DismissalService.new(salary: 2_000, years_worked: 10, worker_type: 'daily', days_worked: 300).calculate

    # 25 × 10 = 250, capped at 150
    assert_equal 300_000.0, result[:base_ipd]
  end

  # --- Domestic worker tests ---

  test "domestic worker below 90 days gets nothing" do
    result = DismissalService.new(salary: 30_000, years_worked: 0, months_fraction: 2, worker_type: 'domestic').calculate

    # 0 years + 2 months = 60 days < 90
    assert_equal 0.0, result[:base_ipd]
  end

  test "domestic worker above 90 days gets monthly formula" do
    result = DismissalService.new(salary: 30_000, years_worked: 2, worker_type: 'domestic').calculate

    assert_equal 60_000.0, result[:base_ipd]
    assert_equal 2, result[:months_compensation]
  end

  # --- Aggravating factors ---

  test "illness doubles IPD" do
    result = DismissalService.new(salary: 50_000, years_worked: 3, aggravating_factor: 'illness').calculate

    # base = 150,000, aggravating = 150,000 (1× more), total = 300,000
    assert_equal 150_000.0, result[:aggravating_amount]
    assert_equal 300_000.0, result[:total_ipd]
  end

  test "accident triples IPD" do
    result = DismissalService.new(salary: 50_000, years_worked: 3, aggravating_factor: 'accident').calculate

    # base = 150,000, aggravating = 300,000 (2× more), total = 450,000
    assert_equal 300_000.0, result[:aggravating_amount]
    assert_equal 450_000.0, result[:total_ipd]
  end

  test "bps_report triples IPD" do
    result = DismissalService.new(salary: 50_000, years_worked: 3, aggravating_factor: 'bps_report').calculate

    assert_equal 300_000.0, result[:aggravating_amount]
  end

  test "pregnancy adds 6 salaries" do
    result = DismissalService.new(salary: 50_000, years_worked: 3, aggravating_factor: 'pregnancy').calculate

    assert_equal 300_000.0, result[:aggravating_amount]
    assert_equal 450_000.0, result[:total_ipd]
  end

  test "harassment adds 6 salaries" do
    result = DismissalService.new(salary: 50_000, years_worked: 3, aggravating_factor: 'harassment').calculate

    assert_equal 300_000.0, result[:aggravating_amount]
  end

  test "disability adds 6 salaries" do
    result = DismissalService.new(salary: 50_000, years_worked: 3, aggravating_factor: 'disability').calculate

    assert_equal 300_000.0, result[:aggravating_amount]
  end

  test "no aggravating factor means zero extra" do
    result = DismissalService.new(salary: 50_000, years_worked: 3).calculate

    assert_equal 0.0, result[:aggravating_amount]
    assert_nil result[:aggravating_factor]
  end

  # --- General ---

  test "returns currency" do
    result = DismissalService.new(salary: 50_000, years_worked: 3).calculate

    assert_equal "UYU", result[:currency]
  end

  test "returns worker_type" do
    result = DismissalService.new(salary: 50_000, years_worked: 3, worker_type: 'daily', days_worked: 150).calculate

    assert_equal "daily", result[:worker_type]
  end
end
