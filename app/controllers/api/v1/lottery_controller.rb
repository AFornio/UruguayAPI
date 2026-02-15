class Api::V1::LotteryController < ApplicationController
  def result
    game = params[:game].to_s.downcase.strip

    return render json: { error: "El parámetro 'game' es requerido" }, status: :unprocessable_entity if game.blank?

    result = LotteryService.fetch_result(game)

    return render json: { error: "Juego no encontrado. Opciones: #{LotteryService.available_games.join(', ')}" }, status: :not_found unless result

    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def games
    render json: { games: LotteryService.available_games }
  end
end
