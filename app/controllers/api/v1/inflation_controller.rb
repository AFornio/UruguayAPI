class Api::V1::InflationController < ApplicationController
  def indicators
    result = InflationService.fetch_indicators
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
