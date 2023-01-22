class Api::V1::CiController < ApplicationController

  def validate
    return render json: false if params[:ci].blank?
    render json: CiUY.validate(params[:ci])
  end

  def validate_digit
    return render json: { error: 'CI is required' }, status: :unprocessable_entity  if params[:ci].blank?
    render json: CiUY.validation_digit(params[:ci])
  end

  def random
    render json: CiUY.random
  end
end
