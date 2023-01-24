class Api::V1::RatesController < ApplicationController

  def index
    brou_url = "https://www.brou.com.uy/c/portal/render_portlet?p_l_id=20593&p_p_id=cotizacionfull_WAR_broutmfportlet_INSTANCE_otHfewh1klyS"
    response = HTTParty.get(brou_url)
    
    doc = Nokogiri::HTML(response.body)
    table = doc.css('table')
    rates = {}

    table.css('tr')[1..-1].each do |row|
      columns = row.css('td')
      currency = columns[0].css('p.moneda').text
      bid = columns[2].css('p.valor').text.gsub(/\s+/, "")
      ask = columns[4].css('p.valor').text.gsub(/\s+/, "")
      spread_bid = columns[6].css('p.valor').text.gsub(/\s+/, "")
      spread_ask = columns[8].css('p.valor').text.gsub(/\s+/, "")

      currency = I18n.transliterate(currency.gsub(' ', '_').downcase)
      rates[currency] = {
        bid: bid,
        ask: ask,
        spread_bid: spread_bid,
        spread_ask: spread_ask
      }
    end
    render json: rates
  end
end
