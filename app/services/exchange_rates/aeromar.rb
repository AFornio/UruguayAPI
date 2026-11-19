# Aeromar: columnas Compra y Venta; el primer valor de cada una es el dólar.
module ExchangeRates
  class Aeromar
    URL = 'https://aeromar.com.uy/'.freeze

    def self.fetch_all
      buy, sell = Scraper.html(URL).css('.mod-cotizacion .text-center').map { |col| col.at_css('.cot-value')&.text }
      [Base.rate(source: 'aeromar', name: 'Aeromar', kind: 'counter', buy:, sell:, url: URL)]
    end
  end
end
