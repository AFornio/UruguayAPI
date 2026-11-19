# Cotización del dólar en bancos y casas de cambio de Uruguay, con una forma común
# (ver ExchangeRates::Base.rate). Para sumar una fuente: una clase con `self.fetch_all`
# en app/services/exchange_rates/ y su nombre en SOURCES.
module ExchangeRates
  SOURCES = %w[brou itau varlix cambilex indumex gales matriz cambio18 aeromar bcu].freeze

  # Todas las fuentes en paralelo; si una falla, el resto igual se devuelve.
  def self.fetch_all
    results = Scraper.parallel_map(SOURCES) do |source|
      [source, fetch(source)]
    rescue StandardError => e
      [source, e]
    end
    failed, ok = results.partition { |_, result| result.is_a?(StandardError) }

    { rates: ok.flat_map(&:last), errors: failed.to_h { |source, error| [source, error.message] } }
  end

  def self.fetch(source)
    const_get(source.camelize).fetch_all
  end
end
