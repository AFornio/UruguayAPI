# Cambilex: pizarra y "Dólar finza" (operando online), ambos en el HTML de la home.
module ExchangeRates
  class Cambilex
    URL = 'https://cambilex.com.uy/'.freeze
    ROWS = { 'dolar' => %w[Cambilex counter], 'dolar finza' => ['Cambilex Finza', 'online'] }.freeze

    def self.fetch_all
      doc = Scraper.html(URL)
      ROWS.map do |label, (name, kind)|
        buy, sell = Base.row(doc, label, 'cambilex')
        Base.rate(source: 'cambilex', name:, kind:, buy:, sell:, url: URL)
      end
    end
  end
end
