# Cambio Matriz: tabla de cotizaciones en el HTML de la home ("dolar 39.40 - 41.80").
module ExchangeRates
  class Matriz
    URL = 'https://www.cambiomatriz.com.uy/'.freeze

    def self.fetch_all
      buy, sell = Base.row(Scraper.html(URL), 'dolar', 'matriz')
      [Base.rate(source: 'matriz', name: 'Cambio Matriz', kind: 'counter', buy:, sell:, url: URL)]
    end
  end
end
