# Varlix: pizarra en el HTML de la home.
module ExchangeRates
  class Varlix
    URL = 'https://www.varlix.com.uy/'.freeze

    def self.fetch_all
      buy, sell = Base.row(Scraper.html(URL), 'dolar(?: americano)?', 'varlix')
      [Base.rate(source: 'varlix', name: 'Varlix', kind: 'counter', buy:, sell:, url: URL)]
    end
  end
end
