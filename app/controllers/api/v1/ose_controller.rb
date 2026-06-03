class Api::V1::OseController < ApplicationController
  def outages
    result = OseService.fetch_outages
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
