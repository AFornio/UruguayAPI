# Calculadora de Indemnización por Despido (IPD) en Uruguay.
#
# Tipos de trabajador:
#   1. Mensual (Ley 10.489): 1 sueldo por año, máximo 6 meses. Fracción = año completo.
#   2. Jornalero (Ley 10.570): Requiere mín. 100 días trabajados.
#      - 100-239 días: 2 jornales por cada 25 días trabajados
#      - 240+ días: 25 jornales por año de antigüedad
#      - Máximo: 150 jornales
#   3. Doméstico (Ley 18.065): Igual que mensual, mínimo 90 días de empleo.
#
# Factores agravantes:
#   - Enfermedad: 2× IPD
#   - No readmisión tras accidente: 3× IPD
#   - Denuncia BPS: 3× IPD
#   - Embarazo/maternidad: IPD + 6 sueldos
#   - Acoso sexual: IPD + 6 sueldos
#   - Discapacidad: IPD + 6 sueldos
class DismissalService
  MONTHLY_MAX_MONTHS = 6
  DAILY_MIN_DAYS = 100
  DAILY_MID_THRESHOLD = 240
  DAILY_MAX_JORNALES = 150
  DOMESTIC_MIN_DAYS = 90

  MULTIPLIER_FACTORS = {
    'illness' => 2,
    'accident' => 3,
    'bps_report' => 3
  }.freeze

  ADDITIVE_FACTORS = %w[pregnancy harassment disability].freeze

  def initialize(salary:, years_worked:, months_fraction: 0, worker_type: 'monthly',
                 days_worked: 0, aggravating_factor: nil)
    @salary = salary.to_f
    @years_worked = years_worked.to_i
    @months_fraction = months_fraction.to_i
    @worker_type = worker_type.to_s
    @days_worked = days_worked.to_i
    @aggravating_factor = aggravating_factor.to_s.presence
  end

  def calculate
    base = calculate_base
    months = compensation_months
    aggravating = calculate_aggravating(base)
    total = base + aggravating

    {
      base_ipd: base.round(2),
      months_compensation: months,
      aggravating_factor: @aggravating_factor,
      aggravating_amount: aggravating.round(2),
      total_ipd: total.round(2),
      worker_type: @worker_type,
      currency: 'UYU'
    }
  end

  private

  def calculate_base
    case @worker_type
    when 'monthly' then calculate_monthly
    when 'daily' then calculate_daily
    when 'domestic' then calculate_domestic
    else calculate_monthly
    end
  end

  def calculate_monthly
    effective_years = @months_fraction.positive? ? @years_worked + 1 : @years_worked
    months = [effective_years, MONTHLY_MAX_MONTHS].min
    @salary * months
  end

  def calculate_daily
    return 0.0 if @days_worked < DAILY_MIN_DAYS

    daily_rate = @salary

    jornales = if @days_worked < DAILY_MID_THRESHOLD
                 (@days_worked / 25.0).floor * 2
               else
                 effective_years = @months_fraction.positive? ? @years_worked + 1 : @years_worked
                 25 * effective_years
               end

    jornales = [jornales, DAILY_MAX_JORNALES].min
    daily_rate * jornales
  end

  def calculate_domestic
    return 0.0 if total_days_employed < DOMESTIC_MIN_DAYS

    calculate_monthly
  end

  def total_days_employed
    (@years_worked * 365) + (@months_fraction * 30)
  end

  def compensation_months
    case @worker_type
    when 'monthly', 'domestic'
      effective_years = @months_fraction.positive? ? @years_worked + 1 : @years_worked
      [effective_years, MONTHLY_MAX_MONTHS].min
    when 'daily'
      return 0 if @days_worked < DAILY_MIN_DAYS

      if @days_worked < DAILY_MID_THRESHOLD
        (@days_worked / 25.0).floor * 2
      else
        effective_years = @months_fraction.positive? ? @years_worked + 1 : @years_worked
        [25 * effective_years, DAILY_MAX_JORNALES].min
      end
    else
      0
    end
  end

  def calculate_aggravating(base)
    return 0.0 unless @aggravating_factor

    if MULTIPLIER_FACTORS.key?(@aggravating_factor)
      base * (MULTIPLIER_FACTORS[@aggravating_factor] - 1)
    elsif ADDITIVE_FACTORS.include?(@aggravating_factor)
      @salary * 6
    else
      0.0
    end
  end
end
