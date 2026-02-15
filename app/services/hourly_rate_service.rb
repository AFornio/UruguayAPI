# Calculadora de valor hora de trabajo en Uruguay.
#
# Fórmula: Valor hora = Sueldo mensual ÷ Divisor mensual
# Divisor = Horas semanales × 4.33 (semanas promedio por mes)
#
# Recargos:
#   - Horas extra diurnas: +100% (2× base)
#   - Feriados/descanso: +150% (2.5× base)
#   - Nocturnidad (22:00-06:00, >5h consecutivas): +20% (1.2× base) - Ley 19.313
#
# Fuente: datosuruguay.com/calculadora-valor-hora-trabajo
class HourlyRateService
  SECTORS = {
    'commerce' => { weekly_hours: 44, divisor: 190 },
    'domestic' => { weekly_hours: 44, divisor: 190 },
    'industry' => { weekly_hours: 48, divisor: 208 },
    'rural' => { weekly_hours: 48, divisor: 208 },
    'standard' => { weekly_hours: 40, divisor: 173 }
  }.freeze

  OVERTIME_MULTIPLIER = 2.0
  HOLIDAY_MULTIPLIER = 2.5
  NIGHT_MULTIPLIER = 1.2

  def initialize(salary:, sector:)
    @salary = salary.to_f
    @sector = sector.to_s.downcase
  end

  def calculate
    config = SECTORS[@sector]
    return nil unless config

    base_rate = @salary / config[:divisor]

    {
      sector: @sector,
      weekly_hours: config[:weekly_hours],
      monthly_divisor: config[:divisor],
      base_hourly_rate: base_rate.round(2),
      overtime_rate: (base_rate * OVERTIME_MULTIPLIER).round(2),
      holiday_rate: (base_rate * HOLIDAY_MULTIPLIER).round(2),
      night_rate: (base_rate * NIGHT_MULTIPLIER).round(2),
      currency: 'UYU'
    }
  end
end
