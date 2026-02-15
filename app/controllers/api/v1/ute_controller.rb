class Api::V1::UteController < ApplicationController
  def tariffs
    result = UteService.fetch_tariffs
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
