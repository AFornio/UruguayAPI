class Api::V1::BanksController < ApplicationController

  def santander_benefits
    url = 'https://www.santander.com.uy/resultsTodos.json'
    response = HTTParty.get(url)
    json = JSON.parse(response.body)

    discounts_by_category = {}

    json.each do |discount|
      category = discount['categoriaNom']
      discounts_by_category[category] = [] unless discounts_by_category[category]

      discounts_by_category[category] << {
        name: discount['nombre'],
        bodyExtract: discount['bodyExtract'],
        description: discount['body'],
        category: category,
        logo: "https://www.santander.com.uy/beneficios/#{discount['listImageId']}.jpg",
        departments: discount['departamentos']
      }
    end

    render json: discounts_by_category
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
          name: discount['slug'],
          bodyExtract: discount['full_texto'],
          description: discount['descripcion'],
          category: category,
          departments: '',
          logo: "https://beneficios.brou.com.uy/upload/beneficios/logos/#{discount['logo']}"
        }
      end
    end

    render json: discounts_by_category
  end
  
  def scotiabank_benefits
    url = 'https://www.scotiabank.com.uy/Personas/Tarjetas/Beneficios/default'
    response = HTTParty.get(url)
    
    doc = Nokogiri::HTML(response.body)

    discounts_by_category = {}

    script_tags = doc.css('script')
    script_tags.each do |script_tag|
      script_content = script_tag.text
      if script_content.include? 'pushBenefit({'
        json = script_content.split('pushBenefit(')[1].split(');')[0] 
        json = json.gsub('"', '')
        json = json.gsub("'", '')  

        json = json.split("\n")
        benefit = {}
        json.each do |line|
          if line.include? '{' or line.include? '}'
          else
            line = line.gsub("\t", '')
            line = line[0..-2] if line[-1] == ','
            key = line.split(':')[0]
            value = line.split(':')[1..]&.join(':')
            benefit[key] = value&.strip
          end
        end

        category = benefit['categoria']

        discounts_by_category[category] = [] unless discounts_by_category[category]
        discounts_by_category[category] << {
          name: benefit['titulo'],
          bodyExtract: benefit['descripcion'],
          description: benefit['descripcion'],
          category: category,
          departments: benefit['departamentos'],
          logo: benefit['logo'],
        }
      end
    end

    render json: discounts_by_category
  end
end
