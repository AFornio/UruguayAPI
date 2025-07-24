class Api::V1::GrainController < ApplicationController
  def prices
    revista_verde_url = "https://revistaverde.com.uy/precio-mercado-nacional/"

    response = HTTParty.get(revista_verde_url)
    doc = Nokogiri::HTML(response.body)

    preciosMercado = doc.css('#preciosMercado')
    return render json: { error: "No data found" }, status: :not_found if preciosMercado.empty? 

    prices = {}

    international_prices = {}
    international_references = preciosMercado.css('> .row.mb-4')[0]
    international_references.css('.col-12').each do |col|
      name = col.css('h5').text.strip
      logo = col.css('img')[0]['src'] if col.css('img')[0]
      price_table = col.css('table')
      price_table.css('tr').each do |row|
        next if row.css('td').empty?

        date = row.css('td')[0].text.strip
        price = row.css('td')[1].text.strip.gsub(/[\s$]/, '')

        international_prices[name] ||= {}
        international_prices[name][date] ||= {}
        international_prices[name][date][:price] = price
        international_prices[name][date][:currency] = "US$/TON"
        international_prices[name][date][:logo] = logo if logo
      end
    end

    prices[:international] = international_prices

    national_prices = {}
    national_references = preciosMercado.css('> .row')[1]
    puts national_references
    national_references.css('.col-12').each do |col|
      name = col.css('h5').text.strip
      puts name
      logo = col.css('img')[0]['src'] if col.css('img')[0]
      price_table = col.css('table')
      price_table.css('tr').each do |row|
        next if row.css('td').empty?

        date = row.css('td')[0].text.strip
        price = row.css('td')[1].text.strip.gsub(/[\s$]/, '')

        national_prices[name] ||= {}
        national_prices[name][date] ||= {}
        national_prices[name][date][:price] = price
        national_prices[name][date][:currency] = "US$/TON"
        national_prices[name][date][:logo] = logo if logo
      end
    end

    prices[:national] = national_prices

    render json: prices
  end
end