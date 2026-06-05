class Api::V1::MontevideoController < ApplicationController
  def bike_lanes
    result = MontevideoBikeLanesService.fetch_bike_lanes(type: params[:type].presence)
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
