class Api::V1::EconomyController < ApplicationController
  def values
    result = EconomyService.fetch_values
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
