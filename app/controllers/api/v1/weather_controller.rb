class Api::V1::WeatherController < ApplicationController
  def forecast
    department = params[:department].to_s.downcase.strip

    return render json: { error: "El parámetro 'department' es requerido" }, status: :unprocessable_entity if department.blank?

    result = WeatherService.fetch_forecast(department)

    return render json: { error: "Departamento no encontrado. Opciones: #{WeatherService.departments.join(', ')}" }, status: :not_found unless result

    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def current
    department = params[:department].to_s.downcase.strip

    return render json: { error: "El parámetro 'department' es requerido" }, status: :unprocessable_entity if department.blank?

    result = WeatherService.fetch_current(department)

    return render json: { error: "No se encontraron estaciones para el departamento '#{department}'" }, status: :not_found unless result

    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def alerts
    result = WeatherService.fetch_alerts
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
