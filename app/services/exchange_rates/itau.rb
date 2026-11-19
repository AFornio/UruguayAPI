# Itaú: XML que usa su web. US.D es la pizarra y LINK la cotización de Itaú Link.
module ExchangeRates
  class Itau
    URL = 'https://www.itau.com.uy/inst/aci/cotiz.xml'.freeze
    PAGE = 'https://www.itau.com.uy/inst/'.freeze
    CODES = { 'US.D' => %w[Itaú counter], 'LINK' => ['Itaú Link', 'online'] }.freeze

    class << self
      def fetch_all
        rates = Nokogiri::XML(Scraper.get(URL).body).css('cotizacion').to_h do |rate|
          [rate.at_css('moneda').text.strip, rate]
        end
        CODES.map do |code, (name, kind)|
          rate = rates.fetch(code) { raise Base::ParseError, "itau: no encontré #{code}" }
          Base.rate(source: 'itau', name:, kind:, buy: rate.at_css('compra').text,
                    sell: rate.at_css('venta').text, url: PAGE)
        end
      end
    end
  end
end
