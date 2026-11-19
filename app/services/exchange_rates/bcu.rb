# BCU: dólar billete promedio de cierre. Es referencia, no se puede comprar a ese precio.
module ExchangeRates
  class Bcu
    URL = 'https://www.bcu.gub.uy/Paginas/Default.aspx'.freeze

    def self.fetch_all
      value = Scraper.html(URL).at_css('#identificador-moneda-2225 .bcu-number')&.text
      [Base.rate(source: 'bcu', name: 'BCU (referencia)', kind: 'reference', buy: value, sell: value, url: URL)]
    end
  end
end
