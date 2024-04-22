class Api::V1::BanksController < ApplicationController

  def brou_rates
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
  
  def brou_benefits
    base_url = 'https://beneficios.brou.com.uy/beneficios/beneficiosapi'
    categories = [
      {name: 'Enseñanza', url:'?categorias=ensenanza&tarjetas=&ubicaciones=&orden=DESC'},
      {name: 'Espectáculos', url:'?categorias=espectaculos&tarjetas=&ubicaciones=&orden=DESC'},
      {name: 'Hogar', url:'?categorias=hogar&tarjetas=&ubicaciones=&orden=DESC'},
      {name: 'Moda', url:'?categorias=moda&tarjetas=&ubicaciones=&orden=DESC'},
      {name: 'Gastronomía', url:'?categorias=gastronomia&tarjetas=&ubicaciones=&orden=DESC'},
      {name: 'Hotelería', url:'?categorias=hoteleria&tarjetas=&ubicaciones=&orden=DESC'},
      {name: 'Salud estética', url:'?categorias=salud-estetica&tarjetas=&ubicaciones=&orden=DESC'},
      {name: 'Turismo', url:'?categorias=turismo&tarjetas=&ubicaciones=&orden=DESC'},
      {name: 'Tecnología', url:'?categorias=tecnologia&tarjetas=&ubicaciones=&orden=DESC'},
      {name: 'Transporte', url:'?categorias=transporte&tarjetas=&ubicaciones=&orden=DESC'},
      {name: 'Día de beneficios Brou', url:'?categorias=diadebeneficiosbrou&tarjetas=&ubicaciones=&orden=DESC'},
    ]

    discounts_by_category = {}

    categories.each do |category|
      response = HTTParty.get(base_url + category[:url])
      json = JSON.parse(response.body)

      category = category[:name]
      discounts_by_category[category] = [] unless discounts_by_category[category]
      json.each do |discount|
        discounts_by_category[category] << {
          name: discount['slug'].gsub(/-|_/, ' ').capitalize.strip,
          bodyExtract: discount['full_texto'],
          description:  ActionView::Base.full_sanitizer.sanitize(discount['descripcion']),
          category: category,
          departments: '',
          logo: "https://beneficios.brou.com.uy/upload/beneficios/logos/#{discount['logo']}"
        }
      end
    end

    render json: discounts_by_category
  end
  end
