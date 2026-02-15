class Api::V1::TollsController < ApplicationController
  def prices
    result = TollsService.fetch_all
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
