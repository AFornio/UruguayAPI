# BROU: pizarra y eBROU. Fuente: el portlet de cotizaciones de https://www.brou.com.uy
module ExchangeRates
  class Brou
    URL = 'https://www.brou.com.uy/c/portal/render_portlet?p_l_id=20593&p_p_id=cotizacionfull_WAR_broutmfportlet_INSTANCE_otHfewh1klyS'.freeze
    PAGE = 'https://www.brou.com.uy/cotizaciones'.freeze
    ROWS = { 'Dólar' => %w[BROU counter], 'Dólar eBROU' => %w[eBROU online] }.freeze

    class << self
      def fetch_all
        rows = Scraper.html(URL).css('tr').to_h { |row| [row.at_css('p.moneda')&.text&.strip, row] }
        ROWS.map do |currency, (name, kind)|
          row = rows.fetch(currency) { raise Base::ParseError, "brou: no encontré #{currency}" }
          buy, sell = row.css('td').to_a.values_at(2, 4).map { |cell| cell.at_css('p.valor')&.text }
          Base.rate(source: 'brou', name:, kind:, buy:, sell:, url: PAGE)
        end
      end
    end
  end
end
