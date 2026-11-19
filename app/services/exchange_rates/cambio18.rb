# Cambio 18: tabla de Wix en el HTML de la home.
module ExchangeRates
  class Cambio18
    URL = 'https://www.cambio18.com/'.freeze

    def self.fetch_all
      buy, sell = Base.row(Scraper.html(URL), 'dolar', 'cambio18')
      [Base.rate(source: 'cambio18', name: 'Cambio 18', kind: 'counter', buy:, sell:, url: URL)]
    end
  end
end
