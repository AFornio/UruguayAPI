class Api::V1::ExchangeRatesController < ApplicationController
  # Cotización del dólar de todas las fuentes. Si una falla, va en `errors` y el resto se devuelve.
  def index
    render json: ExchangeRates.fetch_all
  end
end
