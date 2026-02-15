# Calculadora de seguro de paro (subsidio por desempleo) en Uruguay.
#
# Por despido (mensual) - Porcentajes decrecientes sobre el promedio salarial:
#   Mes 1: 66%, Mes 2: 57%, Mes 3: 50%, Mes 4: 45%, Mes 5: 42%, Mes 6: 40%
#
# Por suspensión (mensual): 50% fijo, máximo 4 meses.
#
# Por despido (jornalero): 16, 14, 12, 11, 10, 9 jornales por mes.
#
# Suplementos:
#   - Dependientes (cónyuge, hijos < 21, familiares incapacitados): +20%
#   - Mayores de 50: +6 meses adicionales al 40%
#
# Fuentes:
#   - BPS: https://www.bps.gub.uy/3702/seguro-de-desempleo.html
#   - Ley 18.399 (Seguro de Desempleo)
class UnemploymentService
  DISMISSAL_MONTHLY_RATES = [0.66, 0.57, 0.50, 0.45, 0.42, 0.40].freeze
  SUSPENSION_RATE = 0.50
  SUSPENSION_MONTHS = 4
  DISMISSAL_DAILY_JORNALES = [16, 14, 12, 11, 10, 9].freeze
  DEPENDENT_SUPPLEMENT = 0.20
  EXTENSION_MONTHS = 6
  EXTENSION_RATE = 0.40

  def initialize(salary:, reason:, worker_type: 'monthly', daily_rate: 0,
                 has_dependents: false, age: 0)
    @salary = salary.to_f
    @reason = reason.to_s
    @worker_type = worker_type.to_s
    @daily_rate = daily_rate.to_f
    @has_dependents = has_dependents
    @age = age.to_i
  end

  def calculate
    benefits = calculate_benefits
    total = benefits.sum { |b| b[:amount] }

    {
      reason: @reason,
      worker_type: @worker_type,
      average_salary: @salary,
      has_dependents: @has_dependents,
      age_50_plus: @age >= 50,
      monthly_benefits: benefits,
      total_benefit: total.round(2),
      duration_months: benefits.length,
      currency: 'UYU'
    }
  end

  private

  def calculate_benefits
    case @reason
    when 'dismissal'
      @worker_type == 'daily' ? daily_dismissal_benefits : monthly_dismissal_benefits
    when 'suspension'
      suspension_benefits
    else
      []
    end
  end

  def monthly_dismissal_benefits
    benefits = DISMISSAL_MONTHLY_RATES.each_with_index.map do |rate, index|
      amount = @salary * rate
      amount *= (1 + DEPENDENT_SUPPLEMENT) if @has_dependents
      { month: index + 1, amount: amount.round(2) }
    end

    benefits += extension_benefits if @age >= 50

    benefits
  end

  def daily_dismissal_benefits
    benefits = DISMISSAL_DAILY_JORNALES.each_with_index.map do |jornales, index|
      amount = @daily_rate * jornales
      amount *= (1 + DEPENDENT_SUPPLEMENT) if @has_dependents
      { month: index + 1, amount: amount.round(2) }
    end

    benefits += daily_extension_benefits if @age >= 50

    benefits
  end

  def suspension_benefits
    (1..SUSPENSION_MONTHS).map do |month|
      amount = @salary * SUSPENSION_RATE
      amount *= (1 + DEPENDENT_SUPPLEMENT) if @has_dependents
      { month:, amount: amount.round(2) }
    end
  end

  def extension_benefits
    (1..EXTENSION_MONTHS).map do |i|
      amount = @salary * EXTENSION_RATE
      amount *= (1 + DEPENDENT_SUPPLEMENT) if @has_dependents
      { month: DISMISSAL_MONTHLY_RATES.length + i, amount: amount.round(2) }
    end
  end

  def daily_extension_benefits
    (1..EXTENSION_MONTHS).map do |i|
      amount = @daily_rate * 9
      amount *= (1 + DEPENDENT_SUPPLEMENT) if @has_dependents
      { month: DISMISSAL_DAILY_JORNALES.length + i, amount: amount.round(2) }
    end
  end
end
