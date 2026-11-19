# Indumex: API JSON que usa su web. Moneda "1" es el dólar.
module ExchangeRates
  class Indumex
    PAGE = 'https://www.indumex.com/'.freeze
    API_URL = "#{PAGE}Umbraco/api/Pizarra/Cotizaciones?fecha=".freeze
    DOLLAR = '1'.freeze

    def self.fetch_all
      rates = JSON.parse(Scraper.get("#{API_URL}#{Base.today.strftime('%d%m%Y')}").body)
      dollar = rates.find { |rate| rate['Moneda'] == DOLLAR } || raise(Base::ParseError, 'indumex: sin dólar')
      [Base.rate(source: 'indumex', name: 'Indumex', kind: 'counter', buy: dollar['Compra'], sell: dollar['Venta'],
                 url: PAGE)]
    end
  end
end
