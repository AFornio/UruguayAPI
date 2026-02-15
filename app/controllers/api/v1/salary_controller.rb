class Api::V1::SalaryController < ApplicationController
  def net
    salary = params[:salary]

    return render json: { error: "El parámetro 'salary' es requerido" }, status: :unprocessable_entity if salary.blank?
    return render json: { error: "El salario debe ser un número positivo" }, status: :unprocessable_entity if salary.to_f <= 0

    result = SalaryService.new(
      salary:,
      has_spouse: ActiveModel::Type::Boolean.new.cast(params[:has_spouse]),
      children: params.fetch(:children, 0),
      disabled_children: params.fetch(:disabled_children, 0)
    ).calculate

    render json: result
  end

  def aguinaldo
    monthly_salaries = params[:monthly_salaries]

    return render json: { error: "El parámetro 'monthly_salaries' es requerido" }, status: :unprocessable_entity if monthly_salaries.blank?

    salaries = parse_salaries(monthly_salaries)

    return render json: { error: "Los salarios deben ser números positivos" }, status: :unprocessable_entity if salaries.any? { |s| s <= 0 }
    return render json: { error: "Se requieren entre 1 y 6 salarios mensuales" }, status: :unprocessable_entity unless salaries.length.between?(1, 6)

    result = AguinaldoService.new(
      monthly_salaries: salaries,
      has_spouse: ActiveModel::Type::Boolean.new.cast(params[:has_spouse]),
      children: params.fetch(:children, 0),
      disabled_children: params.fetch(:disabled_children, 0)
    ).calculate

    render json: result
  end

  def vacation
    salary = params[:salary]
    years_worked = params[:years_worked]

    return render json: { error: "El parámetro 'salary' es requerido" }, status: :unprocessable_entity if salary.blank?
    return render json: { error: "El salario debe ser un número positivo" }, status: :unprocessable_entity if salary.to_f <= 0
    return render json: { error: "El parámetro 'years_worked' es requerido" }, status: :unprocessable_entity if years_worked.blank?
    return render json: { error: "Los años trabajados deben ser un número no negativo" }, status: :unprocessable_entity if years_worked.to_i.negative?

    result = VacationService.new(
      salary:,
      years_worked:,
      has_spouse: ActiveModel::Type::Boolean.new.cast(params[:has_spouse]),
      children: params.fetch(:children, 0),
      disabled_children: params.fetch(:disabled_children, 0),
      is_domestic: ActiveModel::Type::Boolean.new.cast(params[:is_domestic])
    ).calculate

    render json: result
  end

  def dismissal
    salary = params[:salary]
    years_worked = params[:years_worked]

    return render json: { error: "El parámetro 'salary' es requerido" }, status: :unprocessable_entity if salary.blank?
    return render json: { error: "El salario debe ser un número positivo" }, status: :unprocessable_entity if salary.to_f <= 0
    return render json: { error: "El parámetro 'years_worked' es requerido" }, status: :unprocessable_entity if years_worked.blank?

    result = DismissalService.new(
      salary:,
      years_worked:,
      months_fraction: params.fetch(:months_fraction, 0),
      worker_type: params.fetch(:worker_type, 'monthly'),
      days_worked: params.fetch(:days_worked, 0),
      aggravating_factor: params[:aggravating_factor]
    ).calculate

    render json: result
  end

  def hourly_rate
    salary = params[:salary]
    sector = params[:sector]

    return render json: { error: "El parámetro 'salary' es requerido" }, status: :unprocessable_entity if salary.blank?
    return render json: { error: "El salario debe ser un número positivo" }, status: :unprocessable_entity if salary.to_f <= 0
    return render json: { error: "El parámetro 'sector' es requerido" }, status: :unprocessable_entity if sector.blank?

    result = HourlyRateService.new(salary:, sector:).calculate

    return render json: { error: "Sector inválido. Opciones: commerce, industry, standard, domestic, rural" }, status: :unprocessable_entity unless result

    render json: result
  end

  def unemployment
    salary = params[:salary]
    reason = params[:reason]

    return render json: { error: "El parámetro 'salary' es requerido" }, status: :unprocessable_entity if salary.blank?
    return render json: { error: "El salario debe ser un número positivo" }, status: :unprocessable_entity if salary.to_f <= 0
    return render json: { error: "El parámetro 'reason' es requerido (dismissal o suspension)" }, status: :unprocessable_entity if reason.blank?
    return render json: { error: "Razón inválida. Opciones: dismissal, suspension" }, status: :unprocessable_entity unless %w[dismissal suspension].include?(reason)

    result = UnemploymentService.new(
      salary:,
      reason:,
      worker_type: params.fetch(:worker_type, 'monthly'),
      daily_rate: params.fetch(:daily_rate, 0),
      has_dependents: ActiveModel::Type::Boolean.new.cast(params[:has_dependents]),
      age: params.fetch(:age, 0)
    ).calculate

    render json: result
  end

  private

  def parse_salaries(input)
    case input
    when Array
      input.map(&:to_f)
    when String
      parts = input.split(',').map(&:to_f)
      parts.length == 1 ? Array.new(6, parts.first) : parts
    else
      Array.new(6, input.to_f)
    end
  end
end
