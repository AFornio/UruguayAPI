class Api::V1::StreetMarketsController < ApplicationController
  def index
    render json: StreetMarketsService.fetch_all
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
