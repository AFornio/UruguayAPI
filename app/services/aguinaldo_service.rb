# Calculadora de aguinaldo (Sueldo Anual Complementario) en Uruguay.
#
# El aguinaldo se paga en dos instancias:
#   - Junio: sobre ingresos de diciembre anterior a mayo
#   - Diciembre: sobre ingresos de junio a noviembre
#
# Fórmula: Aguinaldo bruto = Suma de ingresos nominales del semestre ÷ 12
#
# Se aplican las mismas deducciones que al salario mensual:
#   - BPS (15%), FONASA, FRL (0.1%), IRPF
#
# Fuentes:
#   - https://www.bps.gub.uy/10829/aportes-del-trabajador-dependiente.html
#   - Ley 12.840 (aguinaldo sector privado)
#
# Ingresos incluidos: sueldo base, horas extra, comisiones, feriados trabajados, nocturnidad.
# Excluidos: tickets de alimentación, subsidios BPS, salario vacacional (salvo convenio colectivo).
class AguinaldoService
  def initialize(monthly_salaries:, has_spouse: false, children: 0, disabled_children: 0)
    @monthly_salaries = normalize_salaries(monthly_salaries)
    @has_spouse = has_spouse
    @children = children.to_i
    @disabled_children = disabled_children.to_i
  end

  def calculate
    gross = calculate_gross

    deductions_result = SalaryService.new(
      salary: gross,
      has_spouse: @has_spouse,
      children: @children,
      disabled_children: @disabled_children
    ).calculate

    {
      gross_aguinaldo: gross.round(2),
      deductions: deductions_result[:deductions],
      net_aguinaldo: (gross - deductions_result[:deductions][:total]).round(2),
      monthly_salaries: @monthly_salaries,
      currency: 'UYU'
    }
  end

  private

  def calculate_gross
    @monthly_salaries.sum / 12.0
  end

  def normalize_salaries(salaries)
    case salaries
    when Array
      salaries.map(&:to_f)
    else
      Array.new(6, salaries.to_f)
    end
  end
end
