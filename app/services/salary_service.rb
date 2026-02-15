# Calculadora de sueldo líquido (neto) en Uruguay.
#
# Aplica las deducciones obligatorias del sistema tributario y de seguridad social uruguayo
# sobre un salario nominal bruto mensual.
#
# Fuentes y legislación:
#   - BPS (aportes jubilatorios y FONASA): https://www.bps.gub.uy/10829/aportes-del-trabajador-dependiente.html
#   - IRPF Categoría II (rentas del trabajo): https://www.dgi.gub.uy/wdgi/page?2,principal,irpf-702,O,es,0,
#   - FRL (Fondo de Reconversión Laboral): Ley 18.406, art. 6
#   - Valor BPC vigente: https://www.bps.gub.uy/bps/bpc.jsp
#   - Referencia de cálculo: https://salarioliquidouy.com/
#
# IMPORTANTE: Los valores de BPC, topes y franjas se actualizan periódicamente.
# Última actualización de constantes: Febrero 2026 (BPC = $6.177).
class SalaryService
  # Base de Prestaciones y Contribuciones (BPC) vigente.
  # Se actualiza anualmente por el Poder Ejecutivo.
  # Fuente: https://www.bps.gub.uy/bps/bpc.jsp
  BPC = 6_177

  # Aporte jubilatorio obligatorio al BPS: 15% del salario nominal.
  # Tope máximo de salario sujeto a aporte: $236.309 mensuales.
  # Fuente: https://www.bps.gub.uy/10829/aportes-del-trabajador-dependiente.html
  BPS_RATE = 0.15
  BPS_CAP = 236_309

  # Fondo de Reconversión Laboral (FRL): 0.1% del salario nominal.
  # Ley 18.406, artículo 6. Aplica a todos los trabajadores dependientes.
  FRL_RATE = 0.001

  # FONASA (Fondo Nacional de Salud) - Aportes del trabajador.
  # Las tasas varían según el nivel de ingreso y la situación familiar.
  # Umbral: 2.5 BPC mensuales.
  #
  # Hasta 2.5 BPC:  3% base, +2% cónyuge, +0% hijos
  # Sobre 2.5 BPC:  4.5% base, +2% cónyuge, +1.5% hijos
  #
  # Fuente: https://www.bps.gub.uy/10829/aportes-del-trabajador-dependiente.html
  FONASA_RATES = {
    low: { base: 0.03, spouse: 0.02, children: 0.0 },
    high: { base: 0.045, spouse: 0.02, children: 0.015 }
  }.freeze

  FONASA_THRESHOLD = 2.5 # En BPC mensuales

  # IRPF Categoría II - Franjas de impuesto progresivo (en BPC mensuales).
  # Cada franja grava solo el excedente sobre el límite inferior.
  #
  # Fuente: Art. 37 del Título 7 del Texto Ordenado de 1996 (DGI).
  # https://www.dgi.gub.uy/wdgi/page?2,principal,irpf-702,O,es,0,
  IRPF_BANDS = [
    { from: 0, to: 7, rate: 0.0 },
    { from: 7, to: 10, rate: 0.10 },
    { from: 10, to: 15, rate: 0.15 },
    { from: 15, to: 30, rate: 0.24 },
    { from: 30, to: 50, rate: 0.25 },
    { from: 50, to: 75, rate: 0.27 },
    { from: 75, to: 115, rate: 0.31 },
    { from: 115, to: Float::INFINITY, rate: 0.36 }
  ].freeze

  # Tasa de crédito fiscal por deducciones del IRPF.
  # Las deducciones (BPS, FONASA, FRL, deducción primaria, hijos) se suman
  # y se multiplican por esta tasa para obtener el crédito fiscal.
  #   - Ingresos hasta 15 BPC mensuales: tasa 10%
  #   - Ingresos sobre 15 BPC mensuales: tasa 8%
  #
  # Fuente: Art. 38 del Título 7, Texto Ordenado 1996 (DGI).
  IRPF_DEDUCTION_RATE_LOW = 0.10
  IRPF_DEDUCTION_RATE_HIGH = 0.08
  IRPF_DEDUCTION_THRESHOLD = 15 # En BPC mensuales

  # Deducción primaria: 13 BPC anuales (se mensualiza dividiendo entre 12).
  # Aplica a todos los trabajadores como mínimo no imponible del IRPF.
  # Fuente: Art. 38, literal A, Título 7, Texto Ordenado 1996.
  PRIMARY_DEDUCTION_BPC = 13

  # Deducciones por hijos a cargo (anuales en BPC, se mensualizan):
  #   - Sin discapacidad: 20 BPC/año por hijo
  #   - Con discapacidad: 40 BPC/año por hijo
  # Fuente: Art. 38, literal F, Título 7, Texto Ordenado 1996.
  CHILD_DEDUCTION_BPC = 20
  DISABLED_CHILD_DEDUCTION_BPC = 40

  # Incremento del 6% en los ingresos gravados para IRPF cuando el salario
  # supera 10 BPC mensuales. Corresponde al ficto por aporte patronal FONASA.
  # Fuente: Art. 36, Título 7, Texto Ordenado 1996.
  ADDITIONAL_INCOME_RATE = 0.06
  ADDITIONAL_INCOME_THRESHOLD = 10 # En BPC mensuales

  def initialize(salary:, has_spouse: false, children: 0, disabled_children: 0)
    @salary = salary.to_f
    @has_spouse = has_spouse
    @children = children.to_i
    @disabled_children = disabled_children.to_i
  end

  def calculate
    bps = calculate_bps
    fonasa = calculate_fonasa
    frl = calculate_frl
    irpf = calculate_irpf(bps, fonasa, frl)

    total_deductions = bps + fonasa + frl + irpf
    net_salary = @salary - total_deductions

    {
      gross_salary: @salary.round(2),
      deductions: {
        bps: bps.round(2),
        fonasa: fonasa.round(2),
        frl: frl.round(2),
        irpf: irpf.round(2),
        total: total_deductions.round(2)
      },
      net_salary: net_salary.round(2),
      bpc: BPC,
      currency: 'UYU'
    }
  end

  private

  # Aporte jubilatorio: 15% del nominal, con tope de $236.309.
  def calculate_bps
    taxable = [@salary, BPS_CAP].min
    taxable * BPS_RATE
  end

  # FONASA: tasa variable según ingreso (umbral 2.5 BPC) y situación familiar.
  def calculate_fonasa
    threshold = FONASA_THRESHOLD * BPC
    rates = @salary <= threshold ? FONASA_RATES[:low] : FONASA_RATES[:high]

    rate = rates[:base]
    rate += rates[:spouse] if @has_spouse
    rate += rates[:children] if @children.positive? || @disabled_children.positive?

    @salary * rate
  end

  # FRL: 0.1% fijo sobre el salario nominal.
  def calculate_frl
    @salary * FRL_RATE
  end

  # IRPF: impuesto progresivo por franjas menos crédito por deducciones.
  # 1. Si el salario > 10 BPC, se ajusta +6% (ficto patronal FONASA).
  # 2. Se aplican las franjas progresivas sobre el ingreso ajustado.
  # 3. Se calcula el crédito: (BPS + FONASA + FRL + deducción primaria + hijos) * tasa.
  # 4. IRPF = máx(impuesto_bruto - crédito, 0).
  def calculate_irpf(bps, fonasa, frl)
    adjusted_salary = @salary
    adjusted_salary *= (1 + ADDITIONAL_INCOME_RATE) if @salary > ADDITIONAL_INCOME_THRESHOLD * BPC

    irpf_gross = calculate_irpf_bands(adjusted_salary)

    deduction_rate = @salary <= IRPF_DEDUCTION_THRESHOLD * BPC ? IRPF_DEDUCTION_RATE_LOW : IRPF_DEDUCTION_RATE_HIGH

    primary_deduction = PRIMARY_DEDUCTION_BPC * BPC / 12.0
    children_deduction = @children * CHILD_DEDUCTION_BPC * BPC / 12.0
    disabled_children_deduction = @disabled_children * DISABLED_CHILD_DEDUCTION_BPC * BPC / 12.0

    total_deductions = bps + fonasa + frl + primary_deduction + children_deduction + disabled_children_deduction
    deduction_credit = total_deductions * deduction_rate

    [irpf_gross - deduction_credit, 0].max
  end

  # Aplica las franjas progresivas del IRPF al ingreso mensual.
  # Cada franja grava solo el excedente dentro de ese rango.
  def calculate_irpf_bands(income)
    tax = 0.0

    IRPF_BANDS.each do |band|
      lower = band[:from] * BPC
      upper = band[:to] == Float::INFINITY ? Float::INFINITY : band[:to] * BPC

      next if income <= lower

      taxable_in_band = [income, upper].min - lower
      tax += taxable_in_band * band[:rate]
    end

    tax
  end
end
