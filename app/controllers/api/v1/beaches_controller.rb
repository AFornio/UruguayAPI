class Api::V1::BeachesController < ApplicationController
  def index
    render json: BeachesService.fetch_all
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end
end
