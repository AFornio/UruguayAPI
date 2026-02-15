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
end
