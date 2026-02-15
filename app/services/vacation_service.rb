# Calculadora de salario vacacional y días de licencia en Uruguay.
#
# Días de licencia:
#   - Base: 20 días hábiles (Ley 12.590)
#   - A partir del 5to año: +1 día cada 4 años de antigüedad, sin tope
#
# Salario vacacional (Ley 16.101, Decreto 615/989):
#   Fórmula: (Sueldo líquido mensual ÷ 30) × Días de licencia
#
# Deducciones:
#   - Exento de: BPS, FONASA, FRL
#   - Sujeto a: IRPF a tasa marginal máxima (Ley 19.321/2015)
#
# Trabajadores domésticos: +15% adicional sobre el salario vacacional.
class VacationService
  def initialize(salary:, years_worked:, has_spouse: false, children: 0, disabled_children: 0, is_domestic: false)
    @salary = salary.to_f
    @years_worked = years_worked.to_i
    @has_spouse = has_spouse
    @children = children.to_i
    @disabled_children = disabled_children.to_i
    @is_domestic = is_domestic
  end

  def calculate
    days = vacation_days
    salary_result = net_salary_result
    net_monthly = salary_result[:net_salary]

    gross_vacation = (net_monthly / 30.0) * days
    gross_vacation *= 1.15 if @is_domestic

    irpf = calculate_vacation_irpf(gross_vacation)
    net_vacation = gross_vacation - irpf

    {
      vacation_days: days,
      gross_vacation_pay: gross_vacation.round(2),
      irpf: irpf.round(2),
      net_vacation_pay: net_vacation.round(2),
      is_domestic: @is_domestic,
      years_worked: @years_worked,
      currency: 'UYU'
    }
  end

  private

  def vacation_days
    return 20 if @years_worked < 5

    20 + ((@years_worked - 5) / 4) + 1
  end

  def net_salary_result
    SalaryService.new(
      salary: @salary,
      has_spouse: @has_spouse,
      children: @children,
      disabled_children: @disabled_children
    ).calculate
  end

  # IRPF sobre salario vacacional: se aplica la tasa marginal máxima
  # correspondiente al tramo del salario regular del trabajador.
  # Ley 19.321/2015.
  def calculate_vacation_irpf(vacation_pay)
    adjusted_salary = @salary
    adjusted_salary *= (1 + SalaryService::ADDITIONAL_INCOME_RATE) if @salary > SalaryService::ADDITIONAL_INCOME_THRESHOLD * SalaryService::BPC

    marginal_rate = marginal_irpf_rate(adjusted_salary)
    vacation_pay * marginal_rate
  end

  def marginal_irpf_rate(income)
    rate = 0.0

    SalaryService::IRPF_BANDS.each do |band|
      lower = band[:from] * SalaryService::BPC
      break if income <= lower

      rate = band[:rate]
    end

    rate
  end
end
