class Api::V1::CattleController < ApplicationController
    def prices
        acg_url = "https://acg.com.uy/"
        
        response = HTTParty.get(acg_url)
        doc = Nokogiri::HTML(response.body)

        all_columna_boxes = doc.css('#primeraColumnaBoxInformativo')
        
        ganado_gordos = {}
        ganado_gordos_box = all_columna_boxes[0]
        ganado_gordos_box.css('> .col-11').each do |box|
            name = box.css('h5').text.strip
            logo = box.css('img')[0]['src'] if box.css('img')[0]

            price = box.css('h3').text.strip
            currency = "USD"
            description = "por kilo en cuarta balanza"

            ganado_gordos[name] = {
                price: price,
                currency: currency,
                logo: logo,
                description: description
            }
        end

        ovinos = {}
        ovinos_box = all_columna_boxes[1]
        ovinos_box.css('> .col-11').each do |box|
            name = box.css('h5').text.strip
            logo = box.css('img')[0]['src'] if box.css('img')[0]

            price = box.css('h3').text.strip
            currency = "USD"
            description = "por kilo en cuarta balanza"

            ovinos[name] = {
                price: price,
                currency: currency,
                logo: logo,
                description: description
            }
        end

        reposicion = {}
        reposicion_box = doc.css('#reposicion #primeraColumnaBoxInformativo')[0]
        reposicion_box.css('> .col-10').each do |box|
            name = box.css('h5').text.strip
            logo = box.css('img')[0]['src'] if box.css('img')[0]
            
            price = box.css('h3').text.strip
            puts "price"
            puts price
            currency = "USD"
            description = "por kilo en cuarta balanza"

            reposicion[name] = {
                price: price,
                currency: currency,
                logo: logo,
                description: description
            }
        end

        render json: {
            ganado_gordos: ganado_gordos,
            ovinos: ovinos,
            reposicion: reposicion
        }, status: :ok
    end
end
